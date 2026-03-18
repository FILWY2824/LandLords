#ifndef RUNNER_RUNTIME_LOGGER_H_
#define RUNNER_RUNTIME_LOGGER_H_

#include <string>

void RuntimeLogDebug(const std::string& tag, const std::string& message);
void RuntimeLogInfo(const std::string& tag, const std::string& message);
void RuntimeLogWarn(const std::string& tag, const std::string& message);
void RuntimeLogError(const std::string& tag, const std::string& message);

std::string RuntimeLogWindowMessage(unsigned int message);
std::string RuntimeLogWideToUtf8(const std::wstring& value);

#endif  // RUNNER_RUNTIME_LOGGER_H_
