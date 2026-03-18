#pragma once

#include <sstream>
#include <string>
#include <string_view>

namespace landlords::core {

enum class LogLevel {
  kDebug = 0,
  kInfo = 1,
  kWarn = 2,
  kError = 3,
};

LogLevel LoadLogLevelFromEnv();
bool ShouldLog(LogLevel level);
void LogMessage(LogLevel level, std::string_view component, const std::string& message);
std::string_view LogLevelName(LogLevel level);

}  // namespace landlords::core

#define LANDLORDS_LOG(level, component, expr)                                    \
  do {                                                                            \
    if (::landlords::core::ShouldLog(level)) {                                    \
      std::ostringstream landlords_log_stream__;                                  \
      landlords_log_stream__ << expr;                                             \
      ::landlords::core::LogMessage(level, component, landlords_log_stream__.str()); \
    }                                                                             \
  } while (false)
