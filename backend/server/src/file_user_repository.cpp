#include "landlords/persistence/user_repository.h"

#include <cctype>
#include <filesystem>
#include <fstream>
#include <functional>
#include <sstream>
#include <unordered_set>

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

std::vector<std::string> SplitCsv(const std::string& input) {
  std::vector<std::string> result;
  std::stringstream stream(input);
  std::string token;
  while (std::getline(stream, token, ',')) {
    if (!token.empty()) {
      result.push_back(token);
    }
  }
  return result;
}

std::string JoinCsv(const std::vector<std::string>& items) {
  std::string result;
  for (std::size_t index = 0; index < items.size(); ++index) {
    if (index > 0) {
      result.push_back(',');
    }
    result.append(items[index]);
  }
  return result;
}

std::string DefaultPasswordHash() {
  return std::to_string(std::hash<std::string>{}("player1"));
}

std::pair<std::string, std::string> SplitTrailingDigits(const std::string& raw) {
  if (raw.empty()) {
    return {"", ""};
  }
  std::size_t split = raw.size();
  while (split > 0 && std::isdigit(static_cast<unsigned char>(raw[split - 1])) != 0) {
    --split;
  }
  if (split == raw.size()) {
    return {raw, ""};
  }
  return {raw.substr(0, split), raw.substr(split)};
}

core::UserRecord BuildDemoUser() {
  return core::UserRecord{
      .user_id = core::GenerateId("user"),
      .account = "player1",
      .nickname = "玩家1",
      .password_hash = DefaultPasswordHash(),
      .total_score = 0,
      .landlord_wins = 0,
      .landlord_games = 0,
      .farmer_wins = 0,
      .farmer_games = 0,
      .friend_user_ids = {},
  };
}

}  // namespace

FileUserRepository::FileUserRepository(std::filesystem::path file_path)
    : file_path_(std::move(file_path)) {}

std::optional<core::UserRecord> FileUserRepository::FindByAccount(const std::string& account) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  const auto iterator = user_id_by_account_.find(account);
  if (iterator == user_id_by_account_.end()) {
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

std::vector<core::UserRecord> FileUserRepository::ListUsersByIds(
    const std::vector<std::string>& user_ids) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  std::vector<core::UserRecord> result;
  result.reserve(user_ids.size());
  for (const auto& user_id : user_ids) {
    const auto iterator = by_user_id_.find(user_id);
    if (iterator != by_user_id_.end()) {
      result.push_back(iterator->second);
    }
  }
  return result;
}

core::UserRecord FileUserRepository::SaveNewUser(const std::string& account,
                                                 const std::string& nickname,
                                                 const std::string& password_hash) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  core::UserRecord user{
      .user_id = core::GenerateId("user"),
      .account = account,
      .nickname = nickname,
      .password_hash = password_hash,
      .total_score = 0,
      .landlord_wins = 0,
      .landlord_games = 0,
      .farmer_wins = 0,
      .farmer_games = 0,
      .friend_user_ids = {},
  };
  by_user_id_[user.user_id] = user;
  user_id_by_account_[user.account] = user.user_id;
  FlushLocked();
  return user;
}

void FileUserRepository::UpdateUser(const core::UserRecord& user) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  if (const auto iterator = by_user_id_.find(user.user_id); iterator != by_user_id_.end()) {
    user_id_by_account_.erase(iterator->second.account);
  }
  by_user_id_[user.user_id] = user;
  user_id_by_account_[user.account] = user.user_id;
  FlushLocked();
}

void FileUserRepository::LoadLocked() {
  if (loaded_) {
    return;
  }
  loaded_ = true;
  by_user_id_.clear();
  user_id_by_account_.clear();

  if (!std::filesystem::exists(file_path_)) {
    std::filesystem::create_directories(file_path_.parent_path());
    auto demo_user = BuildDemoUser();
    by_user_id_[demo_user.user_id] = demo_user;
    user_id_by_account_[demo_user.account] = demo_user.user_id;
    FlushLocked();
    return;
  }

  std::ifstream input(file_path_);
  std::string line;
  while (std::getline(input, line)) {
    if (line.empty()) {
      continue;
    }

    const auto parts = Split(line);
    core::UserRecord user;
    if (parts.size() >= 11U && parts[0] == "v2") {
      user = core::UserRecord{
          .user_id = parts[1],
          .account = parts[2],
          .nickname = parts[3],
          .password_hash = parts[4],
          .total_score = std::stoi(parts[5]),
          .landlord_wins = std::stoi(parts[6]),
          .landlord_games = std::stoi(parts[7]),
          .farmer_wins = std::stoi(parts[8]),
          .farmer_games = std::stoi(parts[9]),
          .friend_user_ids = SplitCsv(parts[10]),
      };
    } else if (parts.size() == 4U || parts.size() == 8U) {
      user = core::UserRecord{
          .user_id = parts[0],
          .account = parts[1],
          .nickname = parts[1],
          .password_hash = parts[2],
          .total_score = std::stoi(parts[3]),
          .landlord_wins = parts.size() > 4U ? std::stoi(parts[4]) : 0,
          .landlord_games = parts.size() > 5U ? std::stoi(parts[5]) : 0,
          .farmer_wins = parts.size() > 6U ? std::stoi(parts[6]) : 0,
          .farmer_games = parts.size() > 7U ? std::stoi(parts[7]) : 0,
          .friend_user_ids = {},
      };
    } else if (parts.size() == 7U) {
      const auto [legacy_name, password_hash] = SplitTrailingDigits(parts[1]);
      user = core::UserRecord{
          .user_id = parts[0],
          .account = legacy_name.empty() ? parts[1] : legacy_name,
          .nickname = legacy_name.empty() ? parts[1] : legacy_name,
          .password_hash = password_hash.empty() ? DefaultPasswordHash() : password_hash,
          .total_score = std::stoi(parts[2]),
          .landlord_wins = std::stoi(parts[3]),
          .landlord_games = std::stoi(parts[4]),
          .farmer_wins = std::stoi(parts[5]),
          .farmer_games = std::stoi(parts[6]),
          .friend_user_ids = {},
      };
    } else {
      continue;
    }

    if (user.user_id.empty() || user.account.empty()) {
      continue;
    }

    std::unordered_set<std::string> dedup(user.friend_user_ids.begin(), user.friend_user_ids.end());
    user.friend_user_ids.assign(dedup.begin(), dedup.end());
    by_user_id_[user.user_id] = user;
    user_id_by_account_[user.account] = user.user_id;
  }

  if (!user_id_by_account_.contains("player1")) {
    auto demo_user = BuildDemoUser();
    by_user_id_[demo_user.user_id] = demo_user;
    user_id_by_account_[demo_user.account] = demo_user.user_id;
    FlushLocked();
  }
}

void FileUserRepository::FlushLocked() {
  std::filesystem::create_directories(file_path_.parent_path());
  std::ofstream output(file_path_, std::ios::trunc);
  for (const auto& [user_id, user] : by_user_id_) {
    output << "v2|"
           << Escape(user_id) << '|'
           << Escape(user.account) << '|'
           << Escape(user.nickname) << '|'
           << Escape(user.password_hash) << '|'
           << user.total_score << '|'
           << user.landlord_wins << '|'
           << user.landlord_games << '|'
           << user.farmer_wins << '|'
           << user.farmer_games << '|'
           << Escape(JoinCsv(user.friend_user_ids)) << '\n';
  }
}

}  // namespace landlords::persistence
