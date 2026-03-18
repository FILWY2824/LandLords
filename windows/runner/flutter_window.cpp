#include "flutter_window.h"

#include <cstdint>
#include <mmsystem.h>
#include <optional>
#include <sstream>

#include "flutter/generated_plugin_registrant.h"
#include "runtime_logger.h"

namespace {

std::string DescribeWindow(HWND window) {
  if (window == nullptr) {
    return "hwnd=0";
  }
  RECT rect{};
  ::GetWindowRect(window, &rect);
  std::ostringstream stream;
  stream << "hwnd=" << reinterpret_cast<std::uintptr_t>(window)
         << " visible=" << (::IsWindowVisible(window) ? "true" : "false")
         << " rect=" << rect.left << "," << rect.top << " "
         << (rect.right - rect.left) << "x" << (rect.bottom - rect.top);
  return stream.str();
}

std::string DescribeMciError(MCIERROR error_code) {
  if (error_code == 0) {
    return "ok";
  }
  wchar_t buffer[256] = {};
  if (::mciGetErrorStringW(error_code, buffer, sizeof(buffer) / sizeof(wchar_t))) {
    return RuntimeLogWideToUtf8(buffer);
  }
  return "mci_error=" + std::to_string(error_code);
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  RuntimeLogInfo("flutter_window", "OnCreate begin");
  if (!Win32Window::OnCreate()) {
    RuntimeLogError("flutter_window", "base OnCreate failed");
    return false;
  }

  RECT frame = GetClientArea();
  RuntimeLogInfo(
      "flutter_window",
      "client frame=" + std::to_string(frame.right - frame.left) + "x" +
          std::to_string(frame.bottom - frame.top));

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  RuntimeLogInfo(
      "flutter_window",
      "controller created ptr=" +
          std::to_string(reinterpret_cast<std::uintptr_t>(
              flutter_controller_.get())));
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    RuntimeLogError("flutter_window",
                    "controller missing engine or view after creation");
    return false;
  }
  RuntimeLogInfo(
      "flutter_window",
      "engine=" +
          std::to_string(reinterpret_cast<std::uintptr_t>(
              flutter_controller_->engine())) +
          " view=" +
          std::to_string(reinterpret_cast<std::uintptr_t>(
              flutter_controller_->view())));
  RegisterPlugins(flutter_controller_->engine());
  RuntimeLogInfo("flutter_window", "plugins registered");
  RegisterVoiceChannel();
  RuntimeLogInfo("flutter_window", "voice channel registered");
  const auto child_window = flutter_controller_->view()->GetNativeWindow();
  RuntimeLogInfo(
      "flutter_window",
      "native child window=" +
          std::to_string(reinterpret_cast<std::uintptr_t>(child_window)));
  SetChildContent(child_window);
  RuntimeLogInfo("flutter_window",
                 "child attached " + DescribeWindow(child_window));

  flutter_controller_->engine()->SetNextFrameCallback([this]() {
    RuntimeLogInfo("flutter_window", "SetNextFrameCallback fired");
    this->Show();
    if (this->flutter_controller_ != nullptr && this->flutter_controller_->view() != nullptr) {
      const auto child_window = this->flutter_controller_->view()->GetNativeWindow();
      const auto frame = this->GetClientArea();
      ::SetWindowPos(child_window, HWND_TOP, frame.left, frame.top,
                     frame.right - frame.left, frame.bottom - frame.top,
                     SWP_NOACTIVATE | SWP_SHOWWINDOW);
      ::ShowWindow(child_window, SW_SHOW);
      ::UpdateWindow(child_window);
      ::RedrawWindow(child_window, nullptr, nullptr,
                     RDW_INVALIDATE | RDW_UPDATENOW | RDW_ALLCHILDREN);
      RuntimeLogInfo("flutter_window",
                     "after child redraw " + DescribeWindow(child_window));
    }
    RuntimeLogInfo("flutter_window",
                   "after Show parent=" + DescribeWindow(this->GetHandle()) +
                       " child=" + DescribeWindow(
                                     this->flutter_controller_ == nullptr
                                         ? nullptr
                                         : this->flutter_controller_->view()
                                               ->GetNativeWindow()));
  });
  RuntimeLogInfo("flutter_window", "next frame callback registered");

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();
  RuntimeLogInfo("flutter_window", "ForceRedraw requested");

  return true;
}

void FlutterWindow::OnDestroy() {
  RuntimeLogInfo("flutter_window", "OnDestroy begin");
  StopSpeaking();
  StopBackgroundMusic();
  if (voice_ != nullptr) {
    voice_->Release();
    voice_ = nullptr;
  }
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  const auto name = RuntimeLogWindowMessage(message);
  if (message == WM_SHOWWINDOW || message == WM_WINDOWPOSCHANGED ||
      message == WM_SIZE || message == WM_ACTIVATE || message == WM_CLOSE ||
      message == WM_DESTROY || message == WM_FONTCHANGE) {
    RuntimeLogDebug("flutter_window",
                    name + " hwnd=" +
                        std::to_string(reinterpret_cast<std::uintptr_t>(hwnd)) +
                        " wparam=" + std::to_string(wparam) + " lparam=" +
                        std::to_string(lparam));
  } else if (message == WM_PAINT && paint_log_count_ < 6) {
    ++paint_log_count_;
    RuntimeLogDebug("flutter_window",
                    name + " count=" + std::to_string(paint_log_count_));
  } else if (message == WM_ERASEBKGND && erase_log_count_ < 6) {
    ++erase_log_count_;
    RuntimeLogDebug("flutter_window",
                    name + " count=" + std::to_string(erase_log_count_));
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      if (message == WM_FONTCHANGE) {
        RuntimeLogDebug("flutter_window",
                        "message handled by flutter engine: " + name);
      }
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      RuntimeLogInfo("flutter_window", "ReloadSystemFonts");
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::RegisterVoiceChannel() {
  RuntimeLogInfo("flutter_window", "RegisterVoiceChannel begin");
  voice_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "landlords/voice",
          &flutter::StandardMethodCodec::GetInstance());

  voice_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "speak") {
          RuntimeLogDebug("flutter_window", "voice method speak");
          const auto* arguments =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments == nullptr) {
            result->Success();
            return;
          }
          const auto iterator =
              arguments->find(flutter::EncodableValue("text"));
          if (iterator != arguments->end()) {
            if (const auto* text =
                    std::get_if<std::string>(&iterator->second)) {
              SpeakText(*text);
            }
          }
          result->Success();
          return;
        }

        if (call.method_name() == "stop") {
          RuntimeLogDebug("flutter_window", "voice method stop");
          StopSpeaking();
          result->Success();
          return;
        }

        if (call.method_name() == "playErrorEffect") {
          RuntimeLogDebug("flutter_window", "voice method playErrorEffect");
          PlayErrorEffect();
          result->Success();
          return;
        }

        if (call.method_name() == "startBackgroundMusic") {
          RuntimeLogDebug("flutter_window",
                          "voice method startBackgroundMusic");
          StartBackgroundMusic();
          result->Success();
          return;
        }

        if (call.method_name() == "stopBackgroundMusic") {
          RuntimeLogDebug("flutter_window", "voice method stopBackgroundMusic");
          StopBackgroundMusic();
          result->Success();
          return;
        }

        result->NotImplemented();
      });
}

void FlutterWindow::SpeakText(const std::string& text) {
  if (text.empty()) {
    return;
  }
  RuntimeLogDebug("flutter_window", "SpeakText text=" + text);

  if (voice_ == nullptr) {
    if (FAILED(::CoCreateInstance(CLSID_SpVoice, nullptr, CLSCTX_ALL,
                                  IID_ISpVoice,
                                  reinterpret_cast<void**>(&voice_)))) {
      RuntimeLogWarn("flutter_window", "CoCreateInstance(CLSID_SpVoice) failed");
      voice_ = nullptr;
      return;
    }
  }

  const int wide_length =
      MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
  if (wide_length <= 0) {
    return;
  }
  std::wstring wide_text(static_cast<std::size_t>(wide_length), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, wide_text.data(),
                      wide_length);
  voice_->Speak(wide_text.c_str(), SPF_ASYNC | SPF_PURGEBEFORESPEAK, nullptr);
}

void FlutterWindow::StopSpeaking() {
  if (voice_ != nullptr) {
    voice_->Speak(L"", SPF_ASYNC | SPF_PURGEBEFORESPEAK, nullptr);
  }
}

void FlutterWindow::PlayErrorEffect() {
  ::MessageBeep(MB_ICONHAND);
}

void FlutterWindow::StartBackgroundMusic() {
  if (bgm_playing_) {
    RuntimeLogDebug("flutter_window", "StartBackgroundMusic ignored already playing");
    return;
  }
  const auto path = ResolveFlutterAssetPath(L"assets\\audio\\background_music.mp3");
  if (path.empty()) {
    RuntimeLogWarn("flutter_window", "background music asset path empty");
    return;
  }
  RuntimeLogInfo("flutter_window",
                 "StartBackgroundMusic path=" + RuntimeLogWideToUtf8(path));

  std::wstring open_command = L"open \"" + path + L"\" type mpegvideo alias landlords_bgm";
  ::mciSendStringW(L"close landlords_bgm", nullptr, 0, nullptr);
  const auto open_result =
      ::mciSendStringW(open_command.c_str(), nullptr, 0, nullptr);
  if (open_result != 0) {
    RuntimeLogWarn("flutter_window",
                   "background music open failed: " + DescribeMciError(open_result));
    return;
  }
  const auto play_result =
      ::mciSendStringW(L"play landlords_bgm repeat", nullptr, 0, nullptr);
  if (play_result == 0) {
    bgm_playing_ = true;
    RuntimeLogInfo("flutter_window", "background music started");
  } else {
    RuntimeLogWarn("flutter_window",
                   "background music play failed: " + DescribeMciError(play_result));
    ::mciSendStringW(L"close landlords_bgm", nullptr, 0, nullptr);
  }
}

void FlutterWindow::StopBackgroundMusic() {
  if (!bgm_playing_) {
    return;
  }
  RuntimeLogInfo("flutter_window", "StopBackgroundMusic");
  ::mciSendStringW(L"stop landlords_bgm", nullptr, 0, nullptr);
  ::mciSendStringW(L"close landlords_bgm", nullptr, 0, nullptr);
  bgm_playing_ = false;
}

std::wstring FlutterWindow::ResolveFlutterAssetPath(const std::wstring& relative_path) const {
  wchar_t executable_path[MAX_PATH];
  const auto length = ::GetModuleFileNameW(nullptr, executable_path, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return L"";
  }
  const std::filesystem::path path(executable_path);
  return (path.parent_path() / L"data" / L"flutter_assets" / relative_path).wstring();
}
