#pragma once

#include <filesystem>
#include <mutex>

#include "landlords/core/models.h"

namespace landlords::persistence {

class ISystemRepository {
 public:
  virtual ~ISystemRepository() = default;

  virtual core::SystemRecord Get() = 0;
  virtual core::SystemRecord UpdateSupportLikeCount(int delta) = 0;
};

class FileSystemRepository final : public ISystemRepository {
 public:
  explicit FileSystemRepository(std::filesystem::path data_root);

  core::SystemRecord Get() override;
  core::SystemRecord UpdateSupportLikeCount(int delta) override;

 private:
  void LoadLocked();
  void FlushLocked();

  std::filesystem::path data_root_;
  std::filesystem::path system_root_;
  std::filesystem::path system_state_path_;
  core::SystemRecord state_;
  std::mutex mutex_;
};

}  // namespace landlords::persistence
