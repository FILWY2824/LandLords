#pragma once

#include <filesystem>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "landlords/core/models.h"

namespace landlords::persistence {

class IFriendRequestRepository {
 public:
  virtual ~IFriendRequestRepository() = default;

  virtual std::optional<core::FriendRequestRecord> FindById(
      const std::string& request_id) = 0;
  virtual std::optional<core::FriendRequestRecord> FindPendingBetween(
      const std::string& left_user_id,
      const std::string& right_user_id) = 0;
  virtual std::vector<core::FriendRequestRecord> ListForUser(
      const std::string& user_id) = 0;
  virtual core::FriendRequestRecord SaveNewRequest(
      const std::string& requester_user_id,
      const std::string& receiver_user_id,
      std::int64_t created_at_ms) = 0;
  virtual void Update(const core::FriendRequestRecord& request) = 0;
};

class FileFriendRequestRepository final : public IFriendRequestRepository {
 public:
  explicit FileFriendRequestRepository(std::filesystem::path data_root);

  std::optional<core::FriendRequestRecord> FindById(
      const std::string& request_id) override;
  std::optional<core::FriendRequestRecord> FindPendingBetween(
      const std::string& left_user_id,
      const std::string& right_user_id) override;
  std::vector<core::FriendRequestRecord> ListForUser(
      const std::string& user_id) override;
  core::FriendRequestRecord SaveNewRequest(
      const std::string& requester_user_id,
      const std::string& receiver_user_id,
      std::int64_t created_at_ms) override;
  void Update(const core::FriendRequestRecord& request) override;

 private:
  void LoadLocked();
  void LoadStructuredLocked();
  void RebuildUserInboxesLocked();
  void FlushAllLocked();
  void FlushRequestLocked(const core::FriendRequestRecord& request);
  void FlushInboxLocked(const std::string& user_id);

  std::filesystem::path data_root_;
  std::filesystem::path social_root_;
  std::filesystem::path requests_root_;
  std::filesystem::path inbox_root_;
  std::unordered_map<std::string, core::FriendRequestRecord> by_request_id_;
  std::unordered_map<std::string, std::vector<std::string>> request_ids_by_user_;
  bool loaded_ = false;
  std::mutex mutex_;
};

}  // namespace landlords::persistence
