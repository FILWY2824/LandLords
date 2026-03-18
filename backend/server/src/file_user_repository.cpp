#include "landlords/persistence/user_repository.h"

#include <filesystem>
#include <fstream>
#include <functional>
#include <sstream>

#include "landlords/core/models.h"

namespace landlords::persistence {

namespace {

std::string Escape(const std::string& input) {
  std::string result = input;
  for (auto& ch : result) {
    if (ch == '|') {
      ch = '/';
    }
  }
  return result;
}

std::vector<std::string> Split(const std::string& input) {
  std::vector<std::string> result;
  std::stringstream stream(input);
  std::string token;
  while (std::getline(stream, token, '|')) {
    result.push_back(token);
  }
  return result;
}

std::string DefaultPasswordHash() {
  return std::to_string(std::hash<std::string>{}("player1"));
}

}  // namespace

FileUserRepository::FileUserRepository(std::filesystem::path file_path)
    : file_path_(std::move(file_path)) {}

std::optional<core::UserRecord> FileUserRepository::FindByUsername(const std::string& username) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  const auto iterator = user_id_by_username_.find(username);
  if (iterator == user_id_by_username_.end()) {
    return std::nullopt;
  }
  return by_user_id_.at(iterator->second);
}

std::optional<core::UserRecord> FileUserRepository::FindByUserId(const std::string& user_id) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  const auto iterator = by_user_id_.find(user_id);
  if (iterator == by_user_id_.end()) {
    return std::nullopt;
  }
  return iterator->second;
}

core::UserRecord FileUserRepository::SaveNewUser(const std::string& username, const std::string& password_hash) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  core::UserRecord user{
      .user_id = core::GenerateId("user"),
      .username = username,
      .password_hash = password_hash,
      .total_score = 0,
  };
  by_user_id_[user.user_id] = user;
  user_id_by_username_[user.username] = user.user_id;
  FlushLocked();
  return user;
}

void FileUserRepository::UpdateUser(const core::UserRecord& user) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  by_user_id_[user.user_id] = user;
  user_id_by_username_[user.username] = user.user_id;
  FlushLocked();
}

void FileUserRepository::LoadLocked() {
  if (loaded_) {
    return;
  }
  loaded_ = true;
  by_user_id_.clear();
  user_id_by_username_.clear();

  if (!std::filesystem::exists(file_path_)) {
    std::filesystem::create_directories(file_path_.parent_path());
    return;
  }

  std::ifstream input(file_path_);
  std::string line;
  while (std::getline(input, line)) {
    if (line.empty()) {
      continue;
    }
    const auto parts = Split(line);
    if (parts.size() != 4U) {
      continue;
    }
    core::UserRecord user{
        .user_id = parts[0],
        .username = parts[1],
        .password_hash = parts[2],
        .total_score = std::stoi(parts[3]),
    };
    by_user_id_[user.user_id] = user;
    user_id_by_username_[user.username] = user.user_id;
  }

  if (!user_id_by_username_.contains("player1")) {
    core::UserRecord demo_user{
        .user_id = core::GenerateId("user"),
        .username = "player1",
        .password_hash = DefaultPasswordHash(),
        .total_score = 0,
    };
    by_user_id_[demo_user.user_id] = demo_user;
    user_id_by_username_[demo_user.username] = demo_user.user_id;
    FlushLocked();
  }
}

void FileUserRepository::FlushLocked() {
  std::filesystem::create_directories(file_path_.parent_path());
  std::ofstream output(file_path_, std::ios::trunc);
  for (const auto& [user_id, user] : by_user_id_) {
    output << Escape(user_id) << '|'
           << Escape(user.username) << '|'
           << Escape(user.password_hash) << '|'
           << user.total_score << '\n';
  }
}

}  // namespace landlords::persistence
