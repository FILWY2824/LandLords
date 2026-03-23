#include "landlords/persistence/system_repository.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

namespace landlords::persistence {

namespace {

std::vector<std::string> Split(const std::string& input) {
  std::vector<std::string> result;
  std::stringstream stream(input);
  std::string token;
  while (std::getline(stream, token, '|')) {
    result.push_back(token);
  }
  return result;
}

std::optional<std::string> ReadFirstNonEmptyLine(
    const std::filesystem::path& path) {
  std::ifstream input(path, std::ios::binary);
  if (!input.is_open()) {
    return std::nullopt;
  }

  std::string line;
  while (std::getline(input, line)) {
    if (!line.empty()) {
      return line;
    }
  }
  return std::nullopt;
}

void WriteTextFileAtomically(const std::filesystem::path& path,
                             const std::string& content) {
  std::filesystem::create_directories(path.parent_path());
  const auto temp_path = path.string() + ".tmp";
  {
    std::ofstream output(temp_path, std::ios::binary | std::ios::trunc);
    output << content;
  }

  std::error_code error;
  std::filesystem::remove(path, error);
  error.clear();
  std::filesystem::rename(temp_path, path, error);
  if (error) {
    error.clear();
    std::filesystem::copy_file(
        temp_path, path, std::filesystem::copy_options::overwrite_existing, error);
    std::filesystem::remove(temp_path, error);
  }
}

std::optional<core::SystemRecord> ParseSystemRecordLine(const std::string& line) {
  if (line.empty()) {
    return std::nullopt;
  }
  const auto parts = Split(line);
  if (parts.size() < 2U || parts[0] != "v1") {
    return std::nullopt;
  }
  return core::SystemRecord{
      .support_like_count = std::stoi(parts[1]),
  };
}

std::string SerializeSystemRecord(const core::SystemRecord& record) {
  return "v1|" + std::to_string(record.support_like_count);
}

}  // namespace

FileSystemRepository::FileSystemRepository(std::filesystem::path data_root)
    : data_root_(std::move(data_root)),
      system_root_(data_root_ / "system"),
      system_state_path_(system_root_ / "system_state.v1") {}

core::SystemRecord FileSystemRepository::Get() {
  std::lock_guard lock(mutex_);
  LoadLocked();
  return state_;
}

core::SystemRecord FileSystemRepository::UpdateSupportLikeCount(int delta) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  state_.support_like_count = std::max(0, state_.support_like_count + delta);
  FlushLocked();
  return state_;
}

void FileSystemRepository::LoadLocked() {
  if (const auto line = ReadFirstNonEmptyLine(system_state_path_); line.has_value()) {
    if (const auto parsed = ParseSystemRecordLine(*line); parsed.has_value()) {
      state_ = *parsed;
      return;
    }
  }
  state_ = core::SystemRecord{};
  FlushLocked();
}

void FileSystemRepository::FlushLocked() {
  WriteTextFileAtomically(system_state_path_, SerializeSystemRecord(state_) + "\n");
}

}  // namespace landlords::persistence
