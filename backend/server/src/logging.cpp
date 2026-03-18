#include "landlords/core/logging.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <cctype>
#include <cstdlib>
#include <ctime>
#include <iomanip>
#include <iostream>
#include <mutex>
#include <string>

namespace landlords::core {

namespace {

LogLevel ParseLogLevel(const char* raw) {
  if (raw == nullptr) {
    return LogLevel::kInfo;
  }

  std::string value(raw);
  std::transform(value.begin(), value.end(), value.begin(), [](unsigned char ch) {
    return static_cast<char>(std::tolower(ch));
  });

  if (value == "debug") {
    return LogLevel::kDebug;
  }
  if (value == "warn" || value == "warning") {
    return LogLevel::kWarn;
  }
  if (value == "error") {
    return LogLevel::kError;
  }
  return LogLevel::kInfo;
}

std::mutex& LogMutex() {
  static std::mutex mutex;
  return mutex;
}

LogLevel& CurrentLogLevel() {
  static LogLevel level = LoadLogLevelFromEnv();
  return level;
}

std::string TimestampText() {
  const auto now = std::chrono::system_clock::now();
  const std::time_t now_time = std::chrono::system_clock::to_time_t(now);
  const auto millis =
      std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) %
      1000;
  std::tm local_time{};
#ifdef _WIN32
  localtime_s(&local_time, &now_time);
#else
  localtime_r(&now_time, &local_time);
#endif
  std::ostringstream stream;
  stream << std::put_time(&local_time, "%H:%M:%S") << "."
         << std::setw(3) << std::setfill('0') << millis.count();
  return stream.str();
}

std::ostream& StreamForLevel(LogLevel level) {
  return level >= LogLevel::kWarn ? std::cerr : std::cout;
}

}  // namespace

LogLevel LoadLogLevelFromEnv() {
  return ParseLogLevel(std::getenv("LANDLORDS_LOG_LEVEL"));
}

bool ShouldLog(LogLevel level) {
  return static_cast<int>(level) >= static_cast<int>(CurrentLogLevel());
}

void LogMessage(LogLevel level, std::string_view component, const std::string& message) {
  std::lock_guard lock(LogMutex());
  auto& stream = StreamForLevel(level);
  stream << "[" << TimestampText() << "]"
         << "[" << LogLevelName(level) << "]"
         << "[" << component << "] "
         << message << std::endl;
}

std::string_view LogLevelName(LogLevel level) {
  switch (level) {
    case LogLevel::kDebug:
      return "DEBUG";
    case LogLevel::kInfo:
      return "INFO";
    case LogLevel::kWarn:
      return "WARN";
    case LogLevel::kError:
      return "ERROR";
  }
  return "INFO";
}

}  // namespace landlords::core
