#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include <X11/Xlib.h>
#endif
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <stdlib.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  GtkWindow* window;
  FlMethodChannel* window_channel;
  gboolean allow_close;
#ifdef GDK_WINDOWING_X11
  Atom wm_delete_window;
  Atom wm_protocols;
  Atom net_close_window;
#endif
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Intercepts the window close button. If Dart wants the app to keep running
// (minimize to taskbar) we prevent the close and iconify; otherwise we set
// allow_close and close for real.
static void on_window_method_call(FlMethodChannel* channel,
                                  FlMethodCall* method_call,
                                  gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "minimize") == 0) {
    if (self->window != nullptr) {
      gtk_window_iconify(self->window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "hide") == 0) {
    if (self->window != nullptr) {
      gtk_widget_hide(GTK_WIDGET(self->window));
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "show") == 0) {
    if (self->window != nullptr) {
      gtk_widget_show(GTK_WIDGET(self->window));
      gtk_window_present(self->window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else if (strcmp(method, "isVisible") == 0) {
    gboolean visible =
        self->window != nullptr && gtk_widget_get_visible(GTK_WIDGET(self->window));
    g_autoptr(FlValue) result = fl_value_new_bool(visible);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "isMinimized") == 0) {
    gboolean minimized = FALSE;
    if (self->window != nullptr) {
      GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(self->window));
      if (gdk_window != nullptr) {
        minimized = (gdk_window_get_state(gdk_window) & GDK_WINDOW_STATE_ICONIFIED) != 0;
      }
    }
    g_autoptr(FlValue) result = fl_value_new_bool(minimized);
    fl_method_call_respond_success(method_call, result, nullptr);
  } else if (strcmp(method, "close") == 0) {
    self->allow_close = TRUE;
    if (self->window != nullptr) {
      gtk_window_close(self->window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

static void send_close_request_to_dart(MyApplication* self) {
  if (self->window_channel != nullptr) {
    fl_method_channel_invoke_method(self->window_channel,
                                    "onWindowCloseRequested", nullptr,
                                    nullptr, nullptr, nullptr);
  }
}

static gboolean on_window_delete_event(GtkWidget* widget,
                                       GdkEventAny* event,
                                       gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  g_print("delete-event: allow_close=%d\n", self->allow_close);
  if (self->allow_close) {
    self->allow_close = FALSE;
    return FALSE;  // allow the window to close
  }
  send_close_request_to_dart(self);
  return TRUE;  // keep the window open until Dart decides
}

#ifdef GDK_WINDOWING_X11
// Intercepts the WM_DELETE_WINDOW ClientMessage before GTK dispatches it as a
// delete-event. Some Flutter/Linux embedders and window managers bypass the
// ordinary delete-event handler, so filtering at the X11 level keeps the
// close-to-tray behaviour reliable.
static GdkFilterReturn on_x11_event_filter(GdkXEvent* xevent,
                                           GdkEvent* event,
                                           gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  XEvent* xev = static_cast<XEvent*>(xevent);
  if (xev->type == ClientMessage) {
    Atom message_type = xev->xclient.message_type;
    Atom protocol = static_cast<Atom>(xev->xclient.data.l[0]);
    g_print("x11-filter: ClientMessage type=%lu protocol=%lu\n",
            static_cast<unsigned long>(message_type),
            static_cast<unsigned long>(protocol));
    if (message_type == self->wm_protocols &&
        protocol == self->wm_delete_window) {
      g_print("x11-filter: WM_DELETE_WINDOW allow_close=%d\n", self->allow_close);
      if (!self->allow_close) {
        send_close_request_to_dart(self);
        return GDK_FILTER_REMOVE;
      }
      self->allow_close = FALSE;
    } else if (message_type == self->net_close_window) {
      g_print("x11-filter: _NET_CLOSE_WINDOW allow_close=%d\n", self->allow_close);
      if (!self->allow_close) {
        send_close_request_to_dart(self);
        return GDK_FILTER_REMOVE;
      }
      self->allow_close = FALSE;
    }
  }
  return GDK_FILTER_CONTINUE;
}
#endif

// Sets the window icon from the bundled OpenValut app icon.
static void my_application_set_window_icon(GtkWindow* window) {
  g_autofree gchar* exe =
      g_file_read_link("/proc/self/exe", nullptr);
  g_autofree gchar* exe_dir =
      exe != nullptr ? g_path_get_dirname(exe) : g_strdup(g_get_current_dir());
  g_autofree gchar* icon_path = g_build_filename(
      exe_dir, "data", "flutter_assets", "assets", "images",
      "logo_icon.png", nullptr);
  g_autoptr(GError) error = nullptr;
  GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(icon_path, &error);
  if (pixbuf != nullptr) {
    gtk_window_set_icon(window, pixbuf);
    g_object_unref(pixbuf);
  } else {
    g_warning("Unable to load window icon: %s", error->message);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->window = window;

  // Use the window manager's native (server-side) decorations so the window
  // keeps the platform's regular title bar. The close button still reaches us
  // via GTK's delete-event (the WM sends a WM_DELETE_WINDOW ClientMessage),
  // so we can intercept it below and keep the app running instead of exiting.
  gtk_window_set_title(window, "OpenValut");

  // Default window: a 3:2 window sized proportionally to the primary monitor,
  // centered on screen.
  GdkDisplay* display = gdk_display_get_default();
  if (display != nullptr) {
    GdkMonitor* monitor = gdk_display_get_primary_monitor(display);
    if (monitor != nullptr) {
      GdkRectangle monitor_geometry;
      gdk_monitor_get_geometry(monitor, &monitor_geometry);
      gint win_w = monitor_geometry.width * 0.6;
      gint win_h = win_w * 2 / 3;
      if (win_h > monitor_geometry.height * 0.85) {
        win_h = monitor_geometry.height * 0.85;
        win_w = win_h * 3 / 2;
      }
      gtk_window_set_default_size(window, win_w, win_h);
    }
  }
  gtk_window_set_position(window, GTK_WIN_POS_CENTER);
  my_application_set_window_icon(window);
  gtk_widget_show(GTK_WIDGET(window));

  // Some Deepin/AMD X11 environments ship a broken OpenGLES driver where the
  // default Impeller (OpenGLES) backend renders a black frame. Fall back to the
  // mature Skia rendering path, which is more tolerant of these drivers.
  if (g_getenv("FLUTTER_ENGINE_SWITCHES") == nullptr) {
    g_setenv("FLUTTER_ENGINE_SWITCHES", "1", FALSE);
    g_setenv("FLUTTER_ENGINE_SWITCH_1", "enable-impeller=false", FALSE);
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Close-button handling: ask Dart whether to exit or minimize.
  // The Flutter embedder connects its own delete-event handler that stops
  // propagation and shuts down the engine. Disconnect it so our handler can
  // decide whether to hide/minimize or really close.
  guint disconnected =
      g_signal_handlers_disconnect_by_data(window, view);
  g_print("activate: disconnected %u Flutter delete-event handler(s)\n",
          disconnected);
  g_signal_connect(window, "delete-event",
                   G_CALLBACK(on_window_delete_event), self);
  FlBinaryMessenger* messenger =
      fl_engine_get_binary_messenger(fl_view_get_engine(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->window_channel =
      fl_method_channel_new(messenger, "openvalut/window",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->window_channel,
                                            on_window_method_call, self,
                                            nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));

#ifdef GDK_WINDOWING_X11
  // Set up low-level X11 filtering so the close button reliably routes to Dart
  // instead of being handled (and possibly swallowed) by the Flutter embedder.
  // The WM may send WM_DELETE_WINDOW to the top-level GTK window, but some
  // Flutter embedders and window managers send it to the FlView's own X11
  // window, so filter both.
  GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
  GdkWindow* view_gdk_window = gtk_widget_get_window(GTK_WIDGET(view));
  g_print("activate: gdk_window=%p, view_gdk_window=%p, is_x11=%d\n",
          (void*)gdk_window, (void*)view_gdk_window,
          gdk_window != nullptr && GDK_IS_X11_WINDOW(gdk_window));
  if (gdk_window != nullptr && GDK_IS_X11_WINDOW(gdk_window)) {
    Display* display = GDK_DISPLAY_XDISPLAY(gdk_window_get_display(gdk_window));
    self->wm_protocols = XInternAtom(display, "WM_PROTOCOLS", FALSE);
    self->wm_delete_window = XInternAtom(display, "WM_DELETE_WINDOW", FALSE);
    self->net_close_window = XInternAtom(display, "_NET_CLOSE_WINDOW", FALSE);
    g_print("activate: adding X11 filter, wm_protocols=%lu, wm_delete_window=%lu, net_close_window=%lu\n",
            static_cast<unsigned long>(self->wm_protocols),
            static_cast<unsigned long>(self->wm_delete_window),
            static_cast<unsigned long>(self->net_close_window));
    gdk_window_add_filter(gdk_window, on_x11_event_filter, self);
    if (view_gdk_window != nullptr && view_gdk_window != gdk_window &&
        GDK_IS_X11_WINDOW(view_gdk_window)) {
      g_print("activate: adding X11 filter to FlView window\n");
      gdk_window_add_filter(view_gdk_window, on_x11_event_filter, self);
    }
  }
#endif
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
#ifdef GDK_WINDOWING_X11
  if (self->window != nullptr) {
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(self->window));
    if (gdk_window != nullptr) {
      gdk_window_remove_filter(gdk_window, on_x11_event_filter, self);
    }
    // The FlView is constructed inside the window; find it and remove the
    // filter we may have added there as well.
    GList* children = gtk_container_get_children(GTK_CONTAINER(self->window));
    for (GList* l = children; l != nullptr; l = l->next) {
      if (FL_IS_VIEW(GTK_WIDGET(l->data))) {
        GdkWindow* view_gdk_window = gtk_widget_get_window(GTK_WIDGET(l->data));
        if (view_gdk_window != nullptr && view_gdk_window != gdk_window) {
          gdk_window_remove_filter(view_gdk_window, on_x11_event_filter, self);
        }
        break;
      }
    }
    g_list_free(children);
  }
#endif
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->window_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
