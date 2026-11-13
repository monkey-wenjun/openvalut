#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Method channel used to exclude the window from screen capture.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      secure_window_channel_;

  // Method channel used to coordinate close/minimize/hide/show with Dart.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      window_channel_;

  // Method channel used to gate the remembered master password behind Windows
  // Hello (PIN / fingerprint / face).
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      user_presence_channel_;

  // When true, the next WM_CLOSE message is allowed to close the window.
  bool allow_close_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
