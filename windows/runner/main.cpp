#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstdint>
#include <iomanip>
#include <sstream>

#include "flutter_window.h"
#include "runtime_logger.h"
#include "utils.h"

namespace {

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

  flutter::DartProject project(L"data");
  RuntimeLogInfo("main", "DartProject created data_dir=data");

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
