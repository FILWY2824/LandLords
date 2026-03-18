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

  virtual std::optional<core::UserRecord> FindByUsername(const std::string& username) = 0;
  virtual std::optional<core::UserRecord> FindByUserId(const std::string& user_id) = 0;
  virtual core::UserRecord SaveNewUser(const std::string& username, const std::string& password_hash) = 0;
  virtual void UpdateUser(const core::UserRecord& user) = 0;
};

class FileUserRepository final : public IUserRepository {
 public:
  explicit FileUserRepository(std::filesystem::path file_path);

  std::optional<core::UserRecord> FindByUsername(const std::string& username) override;
  std::optional<core::UserRecord> FindByUserId(const std::string& user_id) override;
  core::UserRecord SaveNewUser(const std::string& username, const std::string& password_hash) override;
  void UpdateUser(const core::UserRecord& user) override;

 private:
  void LoadLocked();
  void FlushLocked();

  std::filesystem::path file_path_;
  std::unordered_map<std::string, core::UserRecord> by_user_id_;
  std::unordered_map<std::string, std::string> user_id_by_username_;
  bool loaded_ = false;
  std::mutex mutex_;
};

}  // namespace landlords::persistence
