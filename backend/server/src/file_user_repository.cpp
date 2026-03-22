#include "landlords/persistence/user_repository.h"

#include <algorithm>
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

core::UserRecord BuildDemoUser() {
  return core::UserRecord{
      .user_id = core::GenerateId("user"),
      .account = "player1",
      .nickname = "player1",
      .password_hash = DefaultPasswordHash(),
      .total_score = 0,
      .landlord_wins = 0,
      .landlord_games = 0,
      .farmer_wins = 0,
      .farmer_games = 0,
      .friend_user_ids = {},
  };
}

std::filesystem::path UserProfilePath(const std::filesystem::path& users_root,
                                      const std::string& user_id) {
  return users_root / user_id / "profile.v2";
}

void RemoveObsoleteLegacyUserDb(const std::filesystem::path& data_root) {
  std::error_code error;
  std::filesystem::remove(data_root / "users.db", error);
}

bool DirectoryHasEntries(const std::filesystem::path& path) {
  std::error_code error;
  return std::filesystem::exists(path, error) &&
         std::filesystem::directory_iterator(path, error) !=
             std::filesystem::directory_iterator();
}

void DeduplicatePreserveOrder(std::vector<std::string>* values) {
  std::unordered_set<std::string> seen;
  std::vector<std::string> result;
  result.reserve(values->size());
  for (const auto& value : *values) {
    if (value.empty() || seen.contains(value)) {
      continue;
    }
    seen.insert(value);
    result.push_back(value);
  }
  *values = std::move(result);
}

std::optional<core::UserRecord> ParseUserRecordLine(const std::string& line) {
  if (line.empty()) {
    return std::nullopt;
  }

  const auto parts = Split(line);
  if (parts.size() < 10U || parts[0] != "v2") {
    return std::nullopt;
  }
  core::UserRecord user{
      .user_id = parts[1],
      .account = parts[2],
      .nickname = parts[3],
      .password_hash = parts[4],
      .total_score = std::stoi(parts[5]),
      .landlord_wins = std::stoi(parts[6]),
      .landlord_games = std::stoi(parts[7]),
      .farmer_wins = std::stoi(parts[8]),
      .farmer_games = std::stoi(parts[9]),
      .friend_user_ids = parts.size() >= 11U ? SplitCsv(parts[10]) : std::vector<std::string>{},
  };

  if (user.user_id.empty() || user.account.empty()) {
    return std::nullopt;
  }

  DeduplicatePreserveOrder(&user.friend_user_ids);
  return user;
}

std::string SerializeUserRecord(const core::UserRecord& user) {
  return "v2|" + Escape(user.user_id) + "|" + Escape(user.account) + "|" +
         Escape(user.nickname) + "|" + Escape(user.password_hash) + "|" +
         std::to_string(user.total_score) + "|" +
         std::to_string(user.landlord_wins) + "|" +
         std::to_string(user.landlord_games) + "|" +
         std::to_string(user.farmer_wins) + "|" +
         std::to_string(user.farmer_games) + "|" +
         Escape(JoinCsv(user.friend_user_ids));
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

}  // namespace

FileUserRepository::FileUserRepository(std::filesystem::path data_root)
    : data_root_(std::move(data_root)),
      users_root_(data_root_ / "users"),
      index_root_(data_root_ / "index"),
      account_index_path_(index_root_ / "users_by_account.v1") {}

std::optional<core::UserRecord> FileUserRepository::FindByAccount(
    const std::string& account) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  const auto iterator = user_id_by_account_.find(account);
  if (iterator != user_id_by_account_.end()) {
    return by_user_id_.at(iterator->second);
  }

  for (const auto& [user_id, user] : by_user_id_) {
    static_cast<void>(user_id);
    if (user.account != account) {
      continue;
    }
    user_id_by_account_[user.account] = user.user_id;
    FlushAccountIndexLocked();
    return user;
  }

  if (std::filesystem::exists(users_root_)) {
    for (const auto& entry : std::filesystem::directory_iterator(users_root_)) {
      if (!entry.is_directory()) {
        continue;
      }
      const auto line = ReadFirstNonEmptyLine(
          UserProfilePath(users_root_, entry.path().filename().string()));
      if (!line.has_value()) {
        continue;
      }
      const auto user = ParseUserRecordLine(*line);
      if (!user.has_value()) {
        continue;
      }
      by_user_id_[user->user_id] = *user;
      user_id_by_account_[user->account] = user->user_id;
      if (user->account == account) {
        FlushAccountIndexLocked();
        return *user;
      }
    }
  }

  return std::nullopt;
}

std::optional<core::UserRecord> FileUserRepository::FindByUserId(
    const std::string& user_id) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  const auto iterator = by_user_id_.find(user_id);
  if (iterator != by_user_id_.end()) {
    return iterator->second;
  }

  const auto line = ReadFirstNonEmptyLine(UserProfilePath(users_root_, user_id));
  if (!line.has_value()) {
    return std::nullopt;
  }
  const auto user = ParseUserRecordLine(*line);
  if (!user.has_value()) {
    return std::nullopt;
  }
  by_user_id_[user->user_id] = *user;
  user_id_by_account_[user->account] = user->user_id;
  FlushAccountIndexLocked();
  return *user;
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
  FlushUserLocked(user);
  FlushAccountIndexLocked();
  return user;
}

void FileUserRepository::UpdateUser(const core::UserRecord& user) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  if (const auto iterator = by_user_id_.find(user.user_id);
      iterator != by_user_id_.end()) {
    user_id_by_account_.erase(iterator->second.account);
  }
  auto normalized = user;
  DeduplicatePreserveOrder(&normalized.friend_user_ids);
  by_user_id_[normalized.user_id] = normalized;
  user_id_by_account_[normalized.account] = normalized.user_id;
  FlushUserLocked(normalized);
  FlushAccountIndexLocked();
}

void FileUserRepository::LoadLocked() {
  RemoveObsoleteLegacyUserDb(data_root_);
  by_user_id_.clear();
  user_id_by_account_.clear();

  const bool structured_present =
      DirectoryHasEntries(users_root_) ||
      std::filesystem::exists(account_index_path_);
  if (structured_present) {
    LoadStructuredLocked();
  }

  EnsureDefaultUsersLocked();
  if (!structured_present || !std::filesystem::exists(account_index_path_)) {
    FlushAllLocked();
  }
}

void FileUserRepository::LoadStructuredLocked() {
  if (std::filesystem::exists(users_root_)) {
    for (const auto& entry : std::filesystem::directory_iterator(users_root_)) {
      if (!entry.is_directory()) {
        continue;
      }
      const auto line = ReadFirstNonEmptyLine(
          UserProfilePath(users_root_, entry.path().filename().string()));
      if (!line.has_value()) {
        continue;
      }
      const auto user = ParseUserRecordLine(*line);
      if (!user.has_value()) {
        continue;
      }
      by_user_id_[user->user_id] = *user;
      user_id_by_account_[user->account] = user->user_id;
    }
  }

  if (!by_user_id_.empty() || !std::filesystem::exists(account_index_path_)) {
    return;
  }

  std::ifstream input(account_index_path_);
  std::string line;
  while (std::getline(input, line)) {
    const auto parts = Split(line);
    if (parts.size() < 3U || parts[0] != "v1") {
      continue;
    }
    const auto profile_line =
        ReadFirstNonEmptyLine(UserProfilePath(users_root_, parts[2]));
    if (!profile_line.has_value()) {
      continue;
    }
    const auto user = ParseUserRecordLine(*profile_line);
    if (!user.has_value()) {
      continue;
    }
    by_user_id_[user->user_id] = *user;
    user_id_by_account_[user->account] = user->user_id;
  }
}

void FileUserRepository::EnsureDefaultUsersLocked() {
  if (user_id_by_account_.contains("player1")) {
    return;
  }
  auto demo_user = BuildDemoUser();
  by_user_id_[demo_user.user_id] = demo_user;
  user_id_by_account_[demo_user.account] = demo_user.user_id;
}

void FileUserRepository::FlushAllLocked() {
  std::filesystem::create_directories(users_root_);
  std::filesystem::create_directories(index_root_);
  for (const auto& [user_id, user] : by_user_id_) {
    static_cast<void>(user_id);
    FlushUserLocked(user);
  }
  FlushAccountIndexLocked();
}

void FileUserRepository::FlushUserLocked(const core::UserRecord& user) {
  WriteTextFileAtomically(
      UserProfilePath(users_root_, user.user_id),
      SerializeUserRecord(user) + "\n");
}

void FileUserRepository::FlushAccountIndexLocked() {
  std::filesystem::create_directories(index_root_);
  std::vector<std::pair<std::string, std::string>> entries;
  entries.reserve(user_id_by_account_.size());
  for (const auto& [account, user_id] : user_id_by_account_) {
    entries.emplace_back(account, user_id);
  }
  std::sort(entries.begin(), entries.end());

  std::string content;
  for (const auto& [account, user_id] : entries) {
    content.append("v1|");
    content.append(Escape(account));
    content.push_back('|');
    content.append(Escape(user_id));
    content.push_back('\n');
  }
  WriteTextFileAtomically(account_index_path_, content);
}

}  // namespace landlords::persistence

