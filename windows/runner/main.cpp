#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <iomanip>
#include <optional>
#include <sstream>

#include "flutter_window.h"
#include "runtime_logger.h"
#include "utils.h"

namespace {

std::filesystem::path ResolveExecutableDirectory() {
  wchar_t executable_path[MAX_PATH];
  const auto length = ::GetModuleFileNameW(nullptr, executable_path, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return std::filesystem::current_path();
  }
  return std::filesystem::path(executable_path).parent_path();
}

std::optional<std::wstring> ReadEnvironmentVariable(const wchar_t* name) {
  const auto required_size = ::GetEnvironmentVariableW(name, nullptr, 0);
  if (required_size == 0) {
    return std::nullopt;
  }
  std::wstring value(required_size - 1, L'\0');
  ::GetEnvironmentVariableW(name, value.data(), required_size);
  return value;
}

int ReadFlutterEngineSwitchCount() {
  const auto count_value = ReadEnvironmentVariable(L"FLUTTER_ENGINE_SWITCHES");
  if (!count_value.has_value()) {
    return 0;
  }
  try {
    return std::max(0, std::stoi(*count_value));
  } catch (...) {
    return 0;
  }
}

bool HasFlutterEngineSwitch(const std::wstring& key_prefix) {
  const auto switch_count = ReadFlutterEngineSwitchCount();
  for (int index = 1; index <= switch_count; ++index) {
    std::wostringstream name;
    name << L"FLUTTER_ENGINE_SWITCH_" << index;
    const auto value = ReadEnvironmentVariable(name.str().c_str());
    if (value.has_value() && value->rfind(key_prefix, 0) == 0) {
      return true;
    }
  }
  return false;
}

void AppendFlutterEngineSwitch(const std::wstring& value) {
  const auto switch_count = ReadFlutterEngineSwitchCount();
  std::wostringstream switch_name;
  switch_name << L"FLUTTER_ENGINE_SWITCH_" << (switch_count + 1);
  ::SetEnvironmentVariableW(switch_name.str().c_str(), value.c_str());
  const auto updated_count = std::to_wstring(switch_count + 1);
  ::SetEnvironmentVariableW(L"FLUTTER_ENGINE_SWITCHES", updated_count.c_str());
}

void EnsureDesktopEngineDefaults() {
  if (!HasFlutterEngineSwitch(L"enable-impeller=")) {
    AppendFlutterEngineSwitch(L"enable-impeller=false");
    RuntimeLogInfo("main", "appended engine switch enable-impeller=false");
  } else {
    RuntimeLogInfo("main", "using caller-provided enable-impeller switch");
  }
}

LONG WINAPI LogUnhandledException(EXCEPTION_POINTERS* pointers) {
  std::ostringstream stream;
  stream << "unhandled exception code=0x" << std::hex
         << pointers->ExceptionRecord->ExceptionCode << " address=0x"
         << reinterpret_cast<std::uintptr_t>(
                pointers->ExceptionRecord->ExceptionAddress);
  RuntimeLogError("main", stream.str());
  return EXCEPTION_CONTINUE_SEARCH;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  ::SetUnhandledExceptionFilter(LogUnhandledException);
  RuntimeLogInfo("main", "wWinMain start");

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }
  RuntimeLogInfo("main", "console attachment checked");

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  const auto coinit_result =
      ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  RuntimeLogInfo("main",
                 "CoInitializeEx result=" + std::to_string(coinit_result));

  EnsureDesktopEngineDefaults();

  const auto executable_dir = ResolveExecutableDirectory();
  std::error_code path_error;
  std::filesystem::current_path(executable_dir, path_error);
  RuntimeLogInfo("main",
                 "working directory set to " +
                     RuntimeLogWideToUtf8(executable_dir.wstring()) +
                     (path_error ? " (fallback due to error)" : ""));

  const auto data_dir = executable_dir / L"data";
  flutter::DartProject project(data_dir.wstring());
  RuntimeLogInfo("main",
                 "DartProject created data_dir=" +
                     RuntimeLogWideToUtf8(data_dir.wstring()));

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  RuntimeLogInfo(
      "main", "command line args count=" +
                  std::to_string(command_line_arguments.size()));

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));
  RuntimeLogInfo("main", "dart entrypoint arguments applied");

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  RuntimeLogInfo("main", "creating FlutterWindow 1280x720");
  if (!window.Create(L"landlords", origin, size)) {
    RuntimeLogError("main", "window.Create failed");
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  RuntimeLogInfo("main", "window created successfully");

  ::MSG msg;
  RuntimeLogInfo("main", "message loop enter");
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }
  RuntimeLogInfo("main",
                 "message loop exit wParam=" + std::to_string(msg.wParam));

  ::CoUninitialize();
  RuntimeLogInfo("main", "CoUninitialize complete");
  return EXIT_SUCCESS;
}
