#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// The Dart entrypoint also enforces single-instance, but it runs only after
// this window exists, so a redundant launch painted a blank frame and then
// wedged in exit(). Claim the mutex before creating any window instead.
constexpr wchar_t kInstanceMutexName[] =
    L"design.codeux.openvalut.single-instance";

// Loopback port the running instance's Dart side listens on to be shown again.
constexpr int kInstanceSignalPort = 18293;

void NotifyRunningInstance() {
  WSADATA wsa_data;
  if (::WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0) {
    return;
  }
  SOCKET sock = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (sock != INVALID_SOCKET) {
    sockaddr_in address = {};
    address.sin_family = AF_INET;
    address.sin_port = ::htons(static_cast<u_short>(kInstanceSignalPort));
    address.sin_addr.s_addr = ::htonl(INADDR_LOOPBACK);
    // The listener only needs the accept to happen; a refused connect just
    // means the running instance has not reached its own setup yet.
    ::connect(sock, reinterpret_cast<sockaddr *>(&address), sizeof(address));
    ::closesocket(sock);
  }
  ::WSACleanup();
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  HANDLE instance_mutex = ::CreateMutexW(nullptr, FALSE, kInstanceMutexName);
  if (instance_mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    NotifyRunningInstance();
    ::CloseHandle(instance_mutex);
    return EXIT_SUCCESS;
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.CreateAndShow(L"OpenValut", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (instance_mutex != nullptr) {
    ::CloseHandle(instance_mutex);
  }
  return EXIT_SUCCESS;
}
