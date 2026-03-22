#include "landlords/persistence/friend_request_repository.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <unordered_set>

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

landlords::protocol::FriendRequestStatus ParseStatus(const std::string& raw) {
  if (raw == "handled") {
    return landlords::protocol::FRIEND_REQUEST_STATUS_UNSPECIFIED;
  }
  if (raw == "accepted") {
    return landlords::protocol::FRIEND_REQUEST_STATUS_ACCEPTED;
  }
  if (raw == "rejected") {
    return landlords::protocol::FRIEND_REQUEST_STATUS_REJECTED;
  }
  return landlords::protocol::FRIEND_REQUEST_STATUS_PENDING;
}

std::string StatusToString(landlords::protocol::FriendRequestStatus status) {
  switch (status) {
    case landlords::protocol::FRIEND_REQUEST_STATUS_UNSPECIFIED:
      return "handled";
    case landlords::protocol::FRIEND_REQUEST_STATUS_ACCEPTED:
      return "accepted";
    case landlords::protocol::FRIEND_REQUEST_STATUS_REJECTED:
      return "rejected";
    case landlords::protocol::FRIEND_REQUEST_STATUS_PENDING:
      return "pending";
  }
  return "pending";
}

bool MatchesUsers(const core::FriendRequestRecord& request,
                  const std::string& left_user_id,
                  const std::string& right_user_id) {
  return (request.requester_user_id == left_user_id &&
          request.receiver_user_id == right_user_id) ||
         (request.requester_user_id == right_user_id &&
          request.receiver_user_id == left_user_id);
}

std::filesystem::path FriendRequestPath(const std::filesystem::path& requests_root,
                                        const std::string& request_id) {
  return requests_root / (request_id + ".v1");
}

std::filesystem::path InboxPath(const std::filesystem::path& inbox_root,
                                const std::string& user_id) {
  return inbox_root / (user_id + ".v1");
}

bool DirectoryHasEntries(const std::filesystem::path& path) {
  std::error_code error;
  return std::filesystem::exists(path, error) &&
         std::filesystem::directory_iterator(path, error) !=
             std::filesystem::directory_iterator();
}

void RemoveObsoleteLegacyFriendRequestDb(const std::filesystem::path& data_root) {
  std::error_code error;
  std::filesystem::remove(data_root / "friend_requests.db", error);
}

std::optional<core::FriendRequestRecord> ParseRequestLine(const std::string& line) {
  if (line.empty()) {
    return std::nullopt;
  }

  const auto parts = Split(line);
  if (parts.size() < 7U || parts[0] != "v1") {
    return std::nullopt;
  }
  core::FriendRequestRecord request{
      .request_id = parts[1],
      .requester_user_id = parts[2],
      .receiver_user_id = parts[3],
      .status = ParseStatus(parts[4]),
      .created_at_ms = std::stoll(parts[5]),
      .updated_at_ms = std::stoll(parts[6]),
  };
  if (request.request_id.empty() || request.requester_user_id.empty() ||
      request.receiver_user_id.empty()) {
    return std::nullopt;
  }
  return request;
}

std::string SerializeRequest(const core::FriendRequestRecord& request) {
  return "v1|" + Escape(request.request_id) + "|" +
         Escape(request.requester_user_id) + "|" +
         Escape(request.receiver_user_id) + "|" +
         Escape(StatusToString(request.status)) + "|" +
         std::to_string(request.created_at_ms) + "|" +
         std::to_string(request.updated_at_ms);
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

void AppendUnique(std::vector<std::string>* values, const std::string& value) {
  if (value.empty()) {
    return;
  }
  if (std::find(values->begin(), values->end(), value) == values->end()) {
    values->push_back(value);
  }
}

void RemoveValue(std::vector<std::string>* values, const std::string& value) {
  values->erase(std::remove(values->begin(), values->end(), value), values->end());
}

}  // namespace

FileFriendRequestRepository::FileFriendRequestRepository(
    std::filesystem::path data_root)
    : data_root_(std::move(data_root)),
      social_root_(data_root_ / "social"),
      requests_root_(social_root_ / "friend_requests"),
      inbox_root_(social_root_ / "inboxes") {}

std::optional<core::FriendRequestRecord> FileFriendRequestRepository::FindById(
    const std::string& request_id) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  const auto iterator = by_request_id_.find(request_id);
  if (iterator == by_request_id_.end()) {
    return std::nullopt;
  }
  return iterator->second;
}

std::optional<core::FriendRequestRecord>
FileFriendRequestRepository::FindPendingBetween(
    const std::string& left_user_id,
    const std::string& right_user_id) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  std::optional<core::FriendRequestRecord> latest;
  for (const auto& [request_id, request] : by_request_id_) {
    static_cast<void>(request_id);
    if (request.status != landlords::protocol::FRIEND_REQUEST_STATUS_PENDING ||
        !MatchesUsers(request, left_user_id, right_user_id)) {
      continue;
    }
    if (!latest.has_value() || request.updated_at_ms > latest->updated_at_ms) {
      latest = request;
    }
  }
  return latest;
}

std::vector<core::FriendRequestRecord> FileFriendRequestRepository::ListForUser(
    const std::string& user_id) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  std::vector<core::FriendRequestRecord> result;
  const auto iterator = request_ids_by_user_.find(user_id);
  if (iterator == request_ids_by_user_.end()) {
    return result;
  }

  result.reserve(iterator->second.size());
  for (const auto& request_id : iterator->second) {
    const auto found = by_request_id_.find(request_id);
    if (found != by_request_id_.end()) {
      result.push_back(found->second);
    }
  }
  return result;
}

core::FriendRequestRecord FileFriendRequestRepository::SaveNewRequest(
    const std::string& requester_user_id,
    const std::string& receiver_user_id,
    std::int64_t created_at_ms) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  core::FriendRequestRecord request{
      .request_id = core::GenerateId("friend_request"),
      .requester_user_id = requester_user_id,
      .receiver_user_id = receiver_user_id,
      .status = landlords::protocol::FRIEND_REQUEST_STATUS_PENDING,
      .created_at_ms = created_at_ms,
      .updated_at_ms = created_at_ms,
  };
  by_request_id_[request.request_id] = request;
  AppendUnique(&request_ids_by_user_[requester_user_id], request.request_id);
  AppendUnique(&request_ids_by_user_[receiver_user_id], request.request_id);
  FlushRequestLocked(request);
  FlushInboxLocked(requester_user_id);
  FlushInboxLocked(receiver_user_id);
  return request;
}

void FileFriendRequestRepository::Update(const core::FriendRequestRecord& request) {
  std::lock_guard lock(mutex_);
  LoadLocked();

  std::unordered_set<std::string> affected_users{
      request.requester_user_id,
      request.receiver_user_id,
  };
  if (const auto existing = by_request_id_.find(request.request_id);
      existing != by_request_id_.end()) {
    affected_users.insert(existing->second.requester_user_id);
    affected_users.insert(existing->second.receiver_user_id);
    RemoveValue(&request_ids_by_user_[existing->second.requester_user_id],
                request.request_id);
    RemoveValue(&request_ids_by_user_[existing->second.receiver_user_id],
                request.request_id);
  }

  by_request_id_[request.request_id] = request;
  AppendUnique(&request_ids_by_user_[request.requester_user_id], request.request_id);
  AppendUnique(&request_ids_by_user_[request.receiver_user_id], request.request_id);
  FlushRequestLocked(request);
  for (const auto& user_id : affected_users) {
    FlushInboxLocked(user_id);
  }
}

void FileFriendRequestRepository::LoadLocked() {
  if (loaded_) {
    return;
  }
  loaded_ = true;
  RemoveObsoleteLegacyFriendRequestDb(data_root_);
  by_request_id_.clear();
  request_ids_by_user_.clear();

  const bool structured_present =
      DirectoryHasEntries(requests_root_) ||
      DirectoryHasEntries(inbox_root_);
  if (structured_present) {
    LoadStructuredLocked();
  }

  if (!structured_present || !std::filesystem::exists(inbox_root_)) {
    FlushAllLocked();
  }
}

void FileFriendRequestRepository::LoadStructuredLocked() {
  if (!std::filesystem::exists(requests_root_)) {
    return;
  }

  for (const auto& entry : std::filesystem::directory_iterator(requests_root_)) {
    if (!entry.is_regular_file()) {
      continue;
    }
    const auto line = ReadFirstNonEmptyLine(entry.path());
    if (!line.has_value()) {
      continue;
    }
    const auto request = ParseRequestLine(*line);
    if (!request.has_value()) {
      continue;
    }
    by_request_id_[request->request_id] = *request;
  }
  RebuildUserInboxesLocked();
}

void FileFriendRequestRepository::RebuildUserInboxesLocked() {
  request_ids_by_user_.clear();
  for (const auto& [request_id, request] : by_request_id_) {
    static_cast<void>(request_id);
    AppendUnique(&request_ids_by_user_[request.requester_user_id], request.request_id);
    AppendUnique(&request_ids_by_user_[request.receiver_user_id], request.request_id);
  }
}

void FileFriendRequestRepository::FlushAllLocked() {
  std::filesystem::create_directories(requests_root_);
  std::filesystem::create_directories(inbox_root_);
  for (const auto& [request_id, request] : by_request_id_) {
    static_cast<void>(request_id);
    FlushRequestLocked(request);
  }
  for (const auto& [user_id, request_ids] : request_ids_by_user_) {
    static_cast<void>(request_ids);
    FlushInboxLocked(user_id);
  }
}

void FileFriendRequestRepository::FlushRequestLocked(
    const core::FriendRequestRecord& request) {
  WriteTextFileAtomically(
      FriendRequestPath(requests_root_, request.request_id),
      SerializeRequest(request) + "\n");
}

void FileFriendRequestRepository::FlushInboxLocked(const std::string& user_id) {
  const auto path = InboxPath(inbox_root_, user_id);
  const auto iterator = request_ids_by_user_.find(user_id);
  if (iterator == request_ids_by_user_.end() || iterator->second.empty()) {
    std::error_code error;
    std::filesystem::remove(path, error);
    return;
  }

  std::string content;
  for (const auto& request_id : iterator->second) {
    content.append("v1|");
    content.append(Escape(request_id));
    content.push_back('\n');
  }
  WriteTextFileAtomically(path, content);
}

}  // namespace landlords::persistence
