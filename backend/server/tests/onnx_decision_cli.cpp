#include "landlords/ai/onnx_bot_strategy.h"

#include <fstream>
#include <iostream>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "landlords.pb.h"

namespace {

struct Options {
  std::string model_dir;
  std::string snapshot_path;
};

void PrintUsage() {
  std::cerr << "usage: landlords_onnx_decision_cli --model-dir <dir> --snapshot <file>"
            << std::endl;
}

std::optional<Options> ParseArgs(int argc, char** argv) {
  Options options;
  for (int index = 1; index < argc; ++index) {
    const std::string arg = argv[index];
    if (arg == "--model-dir" && index + 1 < argc) {
      options.model_dir = argv[++index];
    } else if (arg == "--snapshot" && index + 1 < argc) {
      options.snapshot_path = argv[++index];
    } else {
      return std::nullopt;
    }
  }
  if (options.model_dir.empty() || options.snapshot_path.empty()) {
    return std::nullopt;
  }
  return options;
}

std::string JoinCardIds(const std::vector<std::string>& card_ids) {
  std::string joined;
  for (std::size_t index = 0; index < card_ids.size(); ++index) {
    if (index > 0) {
      joined.push_back(',');
    }
    joined.append(card_ids[index]);
  }
  return joined;
}

}  // namespace

int main(int argc, char** argv) {
  GOOGLE_PROTOBUF_VERIFY_VERSION;

  const auto options = ParseArgs(argc, argv);
  if (!options.has_value()) {
    PrintUsage();
    return 2;
  }

  std::ifstream input(options->snapshot_path, std::ios::binary);
  if (!input.is_open()) {
    std::cerr << "failed to open snapshot: " << options->snapshot_path << std::endl;
    return 3;
  }

  landlords::protocol::RoomSnapshot snapshot;
  if (!snapshot.ParseFromIstream(&input)) {
    std::cerr << "failed to parse snapshot: " << options->snapshot_path << std::endl;
    return 4;
  }

  auto strategy =
      landlords::ai::CreateOnnxBotStrategyFromDir(options->model_dir);
  if (strategy == nullptr) {
    std::cerr << "failed to load ONNX strategy: " << options->model_dir << std::endl;
    return 5;
  }

  const auto decision = strategy->ChooseMove(snapshot);
  if (!decision.has_value()) {
    std::cerr << "onnx strategy returned no decision" << std::endl;
    return 6;
  }

  std::cout << "kind="
            << (decision->kind == landlords::ai::BotDecision::Kind::kPass ? "pass"
                                                                           : "play")
            << "\n";
  std::cout << "card_ids=" << JoinCardIds(decision->card_ids) << "\n";
  return 0;
}
