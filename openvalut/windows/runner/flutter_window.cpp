#include "flutter_window.h"

#include <dwmapi.h>

// The C++/WinRT projections are vendored by the Windows SDK; keep their
// warnings out of this translation unit (the runner builds with /W4 /WX).
#pragma warning(push, 0)
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Security.Credentials.UI.h>
#include <winrt/base.h>
#pragma warning(pop)

#include <memory>
#include <optional>
#include <string>
#include <utility>

#include "flutter/generated_plugin_registrant.h"

namespace {

using winrt::Windows::Foundation::AsyncStatus;
using winrt::Windows::Security::Credentials::UI::UserConsentVerificationResult;
using winrt::Windows::Security::Credentials::UI::UserConsentVerifier;

// Human readable name of a [UserConsentVerificationResult], for the log.
const char* VerificationResultName(UserConsentVerificationResult result) {
  switch (result) {
    case UserConsentVerificationResult::Verified:
      return "Verified";
    case UserConsentVerificationResult::DeviceNotPresent:
      return "DeviceNotPresent";
    case UserConsentVerificationResult::NotConfiguredForUser:
      return "NotConfiguredForUser";
    case UserConsentVerificationResult::DisabledByPolicy:
      return "DisabledByPolicy";
    case UserConsentVerificationResult::DeviceBusy:
      return "DeviceBusy";
    case UserConsentVerificationResult::RetriesExhausted:
      return "RetriesExhausted";
    case UserConsentVerificationResult::Canceled:
      return "Canceled";
  }
  return "Unknown";
}

// Asks Windows Hello (PIN or biometric) to verify the current user.
//
// This is the Windows counterpart of the Linux `pkexec` prompt: it makes sure
// the person at the keyboard is present before the remembered master password
// is released. Completion runs on this (STA) apartment thread, which is also
// the Flutter platform thread, so the result can be completed directly.
//
// The request is issued unconditionally, deliberately without a
// `CheckAvailabilityAsync` pre-flight: on machines that only have a Hello PIN
// (no fingerprint / face hardware) that check reports `DeviceNotPresent` and
// would skip the PIN prompt entirely.
void VerifyUserPresence(
    const winrt::hstring& prompt,
    std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    UserConsentVerifier::RequestVerificationAsync(prompt)
        .Completed([result](const auto& operation, AsyncStatus status) {
          if (status != AsyncStatus::Completed) {
            result->Error("windows_hello_error",
                          "Windows Hello did not report a result");
            return;
          }
          const auto verification = operation.GetResults();
          if (verification == UserConsentVerificationResult::Verified) {
            result->Success(flutter::EncodableValue(true));
            return;
          }
          // Not verified (cancelled, not configured, no device, ...). Report
          // the reason so the Dart side can log it, and fall back to the
          // master password.
          result->Error("windows_hello_not_verified",
                        VerificationResultName(verification));
        });
  } catch (const winrt::hresult_error& error) {
    result->Error("windows_hello_error", winrt::to_string(error.message()));
  } catch (...) {
    result->Error("windows_hello_error",
                  "Windows Hello verification failed");
  }
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Exclude the window from screen capture on Windows 10 2004+ so password
  // lists are not visible in screenshots / screen recordings.
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif
  HWND hwnd = GetHandle();
  secure_window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "app.openvalut/secureWindow",
          &flutter::StandardMethodCodec::GetInstance());
  secure_window_channel_->SetMethodCallHandler(
      [hwnd](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != "setSecureWindow") {
          result->NotImplemented();
          return;
        }
        bool secure = true;
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments != nullptr) {
          auto it = arguments->find(flutter::EncodableValue("secure"));
          if (it != arguments->end()) {
            if (const auto* value = std::get_if<bool>(&it->second)) {
              secure = *value;
            }
          }
        }
        if (hwnd != nullptr) {
          SetWindowDisplayAffinity(hwnd,
                                   secure ? WDA_EXCLUDEFROMCAPTURE : WDA_NONE);
        }
        result->Success();
      });

  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "openvalut/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this, hwnd](const flutter::MethodCall<flutter::EncodableValue>& call,
                   std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                       result) {
        if (call.method_name() == "minimize") {
          if (hwnd != nullptr) {
            ShowWindow(hwnd, SW_MINIMIZE);
          }
          result->Success();
        } else if (call.method_name() == "hide") {
          if (hwnd != nullptr) {
            ShowWindow(hwnd, SW_HIDE);
          }
          result->Success();
        } else if (call.method_name() == "show") {
          if (hwnd != nullptr) {
            ShowWindow(hwnd, SW_SHOW);
            SetForegroundWindow(hwnd);
          }
          result->Success();
        } else if (call.method_name() == "isVisible") {
          bool visible = hwnd != nullptr && IsWindowVisible(hwnd);
          result->Success(flutter::EncodableValue(visible));
        } else if (call.method_name() == "isMinimized") {
          bool minimized = hwnd != nullptr && IsIconic(hwnd);
          result->Success(flutter::EncodableValue(minimized));
        } else if (call.method_name() == "close") {
          allow_close_ = true;
          SetQuitOnClose(true);
          if (hwnd != nullptr) {
            SendMessage(hwnd, WM_CLOSE, 0, 0);
          }
          result->Success();
        } else if (call.method_name() == "setDarkTitleBar") {
          bool dark = false;
          const auto* arguments =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments != nullptr) {
            auto it = arguments->find(flutter::EncodableValue("dark"));
            if (it != arguments->end()) {
              if (const auto* value = std::get_if<bool>(&it->second)) {
                dark = *value;
              }
            }
          }
          if (hwnd != nullptr) {
            // The OS draws the title bar, so it needs to be told about the
            // app theme separately from the Flutter view.
            BOOL use_dark = dark ? TRUE : FALSE;
            // DWMWA_USE_IMMERSIVE_DARK_MODE is 20 on current Windows versions
            // and 19 on Windows 10 builds before 18985.
            if (FAILED(DwmSetWindowAttribute(hwnd, 20, &use_dark,
                                             sizeof(use_dark)))) {
              DwmSetWindowAttribute(hwnd, 19, &use_dark, sizeof(use_dark));
            }
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  // Windows Hello gate for the remembered master password (see
  // authenticateForRememberedUnlock in lib/utils/system_auth_io.dart).
  user_presence_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "app.openvalut/userPresence",
          &flutter::StandardMethodCodec::GetInstance());
  user_presence_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "verifyUserPresence") {
          result->NotImplemented();
          return;
        }
        winrt::hstring prompt{L"Verify to unlock OpenValut"};
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments != nullptr) {
          auto it = arguments->find(flutter::EncodableValue("prompt"));
          if (it != arguments->end()) {
            if (const auto* value = std::get_if<std::string>(&it->second)) {
              prompt = winrt::to_hstring(*value);
            }
          }
        }
        VerifyUserPresence(
            prompt,
            std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(
                std::move(result)));
      });
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_CLOSE:
      if (allow_close_) {
        allow_close_ = false;
        break;
      }
      if (window_channel_) {
        window_channel_->InvokeMethod("onWindowCloseRequested", nullptr);
      }
      return 0;

    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
