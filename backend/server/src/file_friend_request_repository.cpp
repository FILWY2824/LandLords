#include "landlords/persistence/friend_request_repository.h"

#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>

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
  // Reuse the protobuf unspecified enum value for historical "handled"
  // entries so older generated clients remain wire-compatible.
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

}  // namespace

FileFriendRequestRepository::FileFriendRequestRepository(
    std::filesystem::path file_path)
    : file_path_(std::move(file_path)) {}

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
  for (const auto& [request_id, request] : by_request_id_) {
    static_cast<void>(request_id);
    if (request.requester_user_id == user_id || request.receiver_user_id == user_id) {
      result.push_back(request);
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
  FlushLocked();
  return request;
}

void FileFriendRequestRepository::Update(const core::FriendRequestRecord& request) {
  std::lock_guard lock(mutex_);
  LoadLocked();
  by_request_id_[request.request_id] = request;
  FlushLocked();
}

void FileFriendRequestRepository::LoadLocked() {
  if (loaded_) {
    return;
  }
  loaded_ = true;
  by_request_id_.clear();

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
    if (parts.size() < 7U || parts[0] != "v1") {
      continue;
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
      continue;
    }
    by_request_id_[request.request_id] = request;
  }
}

void FileFriendRequestRepository::FlushLocked() {
  std::filesystem::create_directories(file_path_.parent_path());
  std::ofstream output(file_path_, std::ios::trunc);
  for (const auto& [request_id, request] : by_request_id_) {
    output << "v1|"
           << Escape(request_id) << '|'
           << Escape(request.requester_user_id) << '|'
           << Escape(request.receiver_user_id) << '|'
           << Escape(StatusToString(request.status)) << '|'
           << request.created_at_ms << '|'
           << request.updated_at_ms << '\n';
  }
}

}  // namespace landlords::persistence
