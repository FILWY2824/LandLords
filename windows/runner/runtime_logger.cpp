#include "runtime_logger.h"

#include <Windows.h>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <mutex>
#include <sstream>

namespace {

std::mutex& LogMutex() {
  static std::mutex mutex;
  return mutex;
}

std::filesystem::path ResolveLogPath() {
  wchar_t executable_path[MAX_PATH];
  const auto length = ::GetModuleFileNameW(nullptr, executable_path, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return std::filesystem::current_path() / "runtime_logs" /
           "windows_runner.log";
  }
  return std::filesystem::path(executable_path).parent_path() / "runtime_logs" /
         "windows_runner.log";
}

std::string CurrentTimestamp() {
  using namespace std::chrono;
  const auto now = system_clock::now();
  const auto millis = duration_cast<milliseconds>(now.time_since_epoch()) % 1000;
  const auto time = system_clock::to_time_t(now);
  std::tm local_time{};
  localtime_s(&local_time, &time);
  std::ostringstream stream;
  stream << std::setfill('0') << std::setw(2) << local_time.tm_hour << ':'
         << std::setw(2) << local_time.tm_min << ':' << std::setw(2)
         << local_time.tm_sec << '.' << std::setw(3) << millis.count();
  return stream.str();
}

void RuntimeLogWrite(const char* level, const std::string& tag,
                     const std::string& message) {
  std::lock_guard<std::mutex> lock(LogMutex());
  const auto log_path = ResolveLogPath();
  std::error_code error;
  std::filesystem::create_directories(log_path.parent_path(), error);
  std::ofstream output(log_path, std::ios::app);
  const std::string line = "[" + CurrentTimestamp() + "][" + level + "][" +
                           tag + "] " + message + "\n";
  output << line;
  output.flush();
  ::OutputDebugStringA(line.c_str());
}

}  // namespace

void RuntimeLogDebug(const std::string& tag, const std::string& message) {
  RuntimeLogWrite("DEBUG", tag, message);
}

void RuntimeLogInfo(const std::string& tag, const std::string& message) {
  RuntimeLogWrite("INFO", tag, message);
}

void RuntimeLogWarn(const std::string& tag, const std::string& message) {
  RuntimeLogWrite("WARN", tag, message);
}

void RuntimeLogError(const std::string& tag, const std::string& message) {
  RuntimeLogWrite("ERROR", tag, message);
}

std::string RuntimeLogWindowMessage(unsigned int message) {
  switch (message) {
    case WM_NCCREATE:
      return "WM_NCCREATE";
    case WM_CREATE:
      return "WM_CREATE";
    case WM_SHOWWINDOW:
      return "WM_SHOWWINDOW";
    case WM_WINDOWPOSCHANGED:
      return "WM_WINDOWPOSCHANGED";
    case WM_SIZE:
      return "WM_SIZE";
    case WM_ACTIVATE:
      return "WM_ACTIVATE";
    case WM_PAINT:
      return "WM_PAINT";
    case WM_ERASEBKGND:
      return "WM_ERASEBKGND";
    case WM_FONTCHANGE:
      return "WM_FONTCHANGE";
    case WM_CLOSE:
      return "WM_CLOSE";
    case WM_DESTROY:
      return "WM_DESTROY";
    default:
      return "WM_" + std::to_string(message);
  }
}

std::string RuntimeLogWideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return {};
  }
  const int size =
      ::WideCharToMultiByte(CP_UTF8, 0, value.data(),
                            static_cast<int>(value.size()), nullptr, 0, nullptr,
                            nullptr);
  if (size <= 0) {
    return {};
  }
  std::string utf8(static_cast<std::size_t>(size), '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, value.data(),
                        static_cast<int>(value.size()), utf8.data(), size,
                        nullptr, nullptr);
  return utf8;
}
