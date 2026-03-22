#pragma once

#include <filesystem>
#include <mutex>
#include <optional>
#include <unordered_map>

#include "landlords/core/models.h"

namespace landlords::persistence {

class IUserRepository {
 public:
  virtual ~IUserRepository() = default;

  virtual std::optional<core::UserRecord> FindByAccount(const std::string& account) = 0;
  virtual std::optional<core::UserRecord> FindByUserId(const std::string& user_id) = 0;
  virtual std::vector<core::UserRecord> ListUsersByIds(const std::vector<std::string>& user_ids) = 0;
  virtual core::UserRecord SaveNewUser(const std::string& account,
                                       const std::string& nickname,
                                       const std::string& password_hash) = 0;
  virtual void UpdateUser(const core::UserRecord& user) = 0;
};

class FileUserRepository final : public IUserRepository {
 public:
  explicit FileUserRepository(std::filesystem::path data_root);

  std::optional<core::UserRecord> FindByAccount(const std::string& account) override;
  std::optional<core::UserRecord> FindByUserId(const std::string& user_id) override;
  std::vector<core::UserRecord> ListUsersByIds(
      const std::vector<std::string>& user_ids) override;
  core::UserRecord SaveNewUser(const std::string& account,
                               const std::string& nickname,
                               const std::string& password_hash) override;
  void UpdateUser(const core::UserRecord& user) override;

 private:
  void LoadLocked();
  void LoadStructuredLocked();
  void EnsureDefaultUsersLocked();
  void FlushAllLocked();
  void FlushUserLocked(const core::UserRecord& user);
  void FlushAccountIndexLocked();

  std::filesystem::path data_root_;
  std::filesystem::path users_root_;
  std::filesystem::path index_root_;
  std::filesystem::path account_index_path_;
  std::unordered_map<std::string, core::UserRecord> by_user_id_;
  std::unordered_map<std::string, std::string> user_id_by_account_;
  bool loaded_ = false;
  std::mutex mutex_;
};

}  // namespace landlords::persistence
