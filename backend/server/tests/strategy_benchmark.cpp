#include "landlords/ai/onnx_bot_strategy.h"
#include "landlords/game/room.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

#include "landlords/core/models.h"

namespace {

using landlords::ai::IBotStrategy;
using landlords::core::GenerateId;
using landlords::core::NowMs;
using landlords::core::PlayerState;
using landlords::game::Room;

struct Candidate {
  std::string key;
  std::string label;
  std::shared_ptr<IBotStrategy> strategy;
};

struct MatchStats {
  int games = 0;
  int wins = 0;
  int landlord_games = 0;
  int landlord_wins = 0;
  int farmer_games = 0;
  int farmer_wins = 0;
  int total_score = 0;
};

struct PairwiseResult {
  MatchStats stats;
};

PlayerState MakeBot(const std::string& name) {
  return PlayerState{
      .player_id = GenerateId("bench_bot"),
      .display_name = name,
      .is_bot = true,
  };
}

void Require(bool condition, const std::string& message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

std::filesystem::path FindRepoRoot() {
  if (const char* configured = std::getenv("LANDLORDS_REPO_ROOT")) {
    if (*configured != '\0') {
      return std::filesystem::path(configured);
    }
  }

  auto current = std::filesystem::current_path();
  while (!current.empty()) {
    if (std::filesystem::exists(current / "pubspec.yaml") &&
        std::filesystem::exists(current / "backend" / "server" / "CMakeLists.txt")) {
      return current;
    }
    const auto parent = current.parent_path();
    if (parent == current) {
      break;
    }
    current = parent;
  }

  throw std::runtime_error("failed to locate repository root; set LANDLORDS_REPO_ROOT");
}

void ConfigureOnnxDirs() {
  const auto repo_root = FindRepoRoot();
  const auto easy_dir = (repo_root / "backend" / "ai_models" / "onnx" / "douzero_ADP")
                            .lexically_normal()
                            .string();
  const auto normal_dir = (repo_root / "backend" / "ai_models" / "onnx" / "sl")
                              .lexically_normal()
                              .string();
  const auto hard_dir = (repo_root / "backend" / "ai_models" / "onnx" / "douzero_WP")
                            .lexically_normal()
                            .string();
#ifdef _WIN32
  _putenv_s("LANDLORDS_DOUZERO_ONNX_DIR_EASY", easy_dir.c_str());
  _putenv_s("LANDLORDS_DOUZERO_ONNX_DIR_NORMAL", normal_dir.c_str());
  _putenv_s("LANDLORDS_DOUZERO_ONNX_DIR_HARD", hard_dir.c_str());
#else
  setenv("LANDLORDS_DOUZERO_ONNX_DIR_EASY", easy_dir.c_str(), 1);
  setenv("LANDLORDS_DOUZERO_ONNX_DIR_NORMAL", normal_dir.c_str(), 1);
  setenv("LANDLORDS_DOUZERO_ONNX_DIR_HARD", hard_dir.c_str(), 1);
#endif
}

int LoadGamesPerSeat() {
  const char* raw = std::getenv("LANDLORDS_BENCH_GAMES_PER_SEAT");
  if (raw == nullptr || *raw == '\0') {
    return 200;
  }
  return std::max(20, std::atoi(raw));
}

std::vector<Candidate> BuildCandidates() {
  ConfigureOnnxDirs();
  const auto repo_root = FindRepoRoot();
  auto sl = landlords::ai::CreateOnnxBotStrategyFromDir(
      (repo_root / "backend" / "ai_models" / "onnx" / "sl").lexically_normal().string());
  auto adp = landlords::ai::CreateOnnxBotStrategyFromDir(
      (repo_root / "backend" / "ai_models" / "onnx" / "douzero_ADP")
          .lexically_normal()
          .string());
  auto wp = landlords::ai::CreateOnnxBotStrategyFromDir(
      (repo_root / "backend" / "ai_models" / "onnx" / "douzero_WP")
          .lexically_normal()
          .string());
  Require(sl != nullptr, "failed to load SL ONNX strategy");
  Require(adp != nullptr, "failed to load ADP ONNX strategy");
  Require(wp != nullptr, "failed to load WP ONNX strategy");

  return {
      Candidate{.key = "sl", .label = "SL", .strategy = std::move(sl)},
      Candidate{.key = "adp", .label = "DouZero-ADP", .strategy = std::move(adp)},
      Candidate{.key = "wp", .label = "DouZero-WP", .strategy = std::move(wp)},
  };
}

MatchStats SimulateOrderedMatchup(const Candidate& primary,
                                  const Candidate& opponent,
                                  int games_per_seat) {
  MatchStats stats;
  for (int seat = 0; seat < 3; ++seat) {
    for (int game = 0; game < games_per_seat; ++game) {
      std::vector<PlayerState> players;
      players.push_back(MakeBot("Seat A"));
      players.push_back(MakeBot("Seat B"));
      players.push_back(MakeBot("Seat C"));

      std::unordered_map<std::string, std::shared_ptr<IBotStrategy>> per_player_strategy;
      per_player_strategy.emplace(players[seat].player_id, primary.strategy);
      Room room(GenerateId("bench_room"),
                landlords::protocol::MATCH_MODE_PVP,
                players,
                landlords::protocol::BOT_DIFFICULTY_NORMAL,
                opponent.strategy,
                per_player_strategy);

      std::int64_t now_ms = NowMs();
      int guard = 0;
      while (!room.finished() && guard < 800) {
        now_ms += 5000;
        room.TickManaged(now_ms, 25000);
        ++guard;
      }

      Require(guard < 800, "strategy benchmark hit turn guard");
      const auto& controlled = room.players()[seat];
      stats.games += 1;
      stats.total_score += controlled.round_score;
      if (controlled.round_score > 0) {
        stats.wins += 1;
      }
      if (controlled.is_landlord) {
        stats.landlord_games += 1;
        if (controlled.round_score > 0) {
          stats.landlord_wins += 1;
        }
      } else {
        stats.farmer_games += 1;
        if (controlled.round_score > 0) {
          stats.farmer_wins += 1;
        }
      }
    }
  }
  return stats;
}

double Percent(int wins, int games) {
  if (games == 0) {
    return 0.0;
  }
  return static_cast<double>(wins) * 100.0 / static_cast<double>(games);
}

double AverageScore(const MatchStats& stats) {
  if (stats.games == 0) {
    return 0.0;
  }
  return static_cast<double>(stats.total_score) / static_cast<double>(stats.games);
}

std::string FormatPercent(double value) {
  std::ostringstream stream;
  stream << std::fixed << std::setprecision(1) << value << "%";
  return stream.str();
}

std::string FormatScore(double value) {
  std::ostringstream stream;
  stream << std::fixed << std::setprecision(2) << value;
  return stream.str();
}

void WriteReport(const std::filesystem::path& path,
                 const std::vector<Candidate>& candidates,
                 const std::map<std::pair<std::string, std::string>, PairwiseResult>& pairwise,
                 int games_per_seat) {
  std::filesystem::create_directories(path.parent_path());
  std::ofstream output(path, std::ios::trunc);
  Require(output.is_open(), "failed to open strategy benchmark report");

  output << "# Dou Dizhu Strategy Benchmark\n\n";
  output << "## Methodology\n\n";
  output << "- Seat-controlled benchmark: one controlled seat uses the primary strategy, the other two seats use the opponent strategy.\n";
  output << "- Games per seat matchup: `" << games_per_seat << "`.\n";
  output << "- Total games per primary/opponent pair: `" << (games_per_seat * 3) << "`.\n";
  output << "- This is stricter than a simple 1v1 win-rate comparison because Dou Dizhu has asymmetric 2v1 cooperation.\n\n";
  output << "## Overall Ranking\n\n";
  output << "| Rank | Candidate | Games | Avg Score | Win Rate | Landlord Win | Farmer Win |\n";
  output << "| --- | --- | ---: | ---: | ---: | ---: | ---: |\n";

  struct AggregateRow {
    std::string label;
    MatchStats stats;
  };
  std::vector<AggregateRow> rows;
  rows.reserve(candidates.size());
  for (const auto& candidate : candidates) {
    AggregateRow row{.label = candidate.label};
    for (const auto& opponent : candidates) {
      if (candidate.key == opponent.key) {
        continue;
      }
      const auto found = pairwise.find({candidate.key, opponent.key});
      if (found == pairwise.end()) {
        continue;
      }
      const auto& stats = found->second.stats;
      row.stats.games += stats.games;
      row.stats.wins += stats.wins;
      row.stats.total_score += stats.total_score;
      row.stats.landlord_games += stats.landlord_games;
      row.stats.landlord_wins += stats.landlord_wins;
      row.stats.farmer_games += stats.farmer_games;
      row.stats.farmer_wins += stats.farmer_wins;
    }
    rows.push_back(std::move(row));
  }

  std::sort(rows.begin(), rows.end(), [](const AggregateRow& left, const AggregateRow& right) {
    if (AverageScore(left.stats) != AverageScore(right.stats)) {
      return AverageScore(left.stats) > AverageScore(right.stats);
    }
    return Percent(left.stats.wins, left.stats.games) >
           Percent(right.stats.wins, right.stats.games);
  });

  for (std::size_t index = 0; index < rows.size(); ++index) {
    const auto& row = rows[index];
    output << "| " << (index + 1)
           << " | " << row.label
           << " | " << row.stats.games
           << " | " << FormatScore(AverageScore(row.stats))
           << " | " << FormatPercent(Percent(row.stats.wins, row.stats.games))
           << " | " << FormatPercent(Percent(row.stats.landlord_wins, row.stats.landlord_games))
           << " | " << FormatPercent(Percent(row.stats.farmer_wins, row.stats.farmer_games))
           << " |\n";
  }

  output << "\n## Pairwise Matrix\n\n";
  output << "| Candidate |";
  for (const auto& opponent : candidates) {
    output << " " << opponent.label << " |";
  }
  output << "\n| --- |";
  for (std::size_t index = 0; index < candidates.size(); ++index) {
    output << " ---: |";
  }
  output << "\n";

  for (const auto& candidate : candidates) {
    output << "| " << candidate.label << " |";
    for (const auto& opponent : candidates) {
      if (candidate.key == opponent.key) {
        output << " - |";
        continue;
      }
      const auto found = pairwise.find({candidate.key, opponent.key});
      Require(found != pairwise.end(), "missing pairwise benchmark result");
      output << " "
             << FormatScore(AverageScore(found->second.stats))
             << " / "
             << FormatPercent(Percent(found->second.stats.wins, found->second.stats.games))
             << " |";
    }
    output << "\n";
  }

  output << "\n## Detailed Matchups\n\n";
  output << "| Primary | Opponent Team | Games | Avg Score | Win Rate | Landlord Win | Farmer Win |\n";
  output << "| --- | --- | ---: | ---: | ---: | ---: | ---: |\n";
  for (const auto& candidate : candidates) {
    for (const auto& opponent : candidates) {
      if (candidate.key == opponent.key) {
        continue;
      }
      const auto found = pairwise.find({candidate.key, opponent.key});
      Require(found != pairwise.end(), "missing detailed benchmark result");
      const auto& stats = found->second.stats;
      output << "| " << candidate.label
             << " | " << opponent.label
             << " | " << stats.games
             << " | " << FormatScore(AverageScore(stats))
             << " | " << FormatPercent(Percent(stats.wins, stats.games))
             << " | " << FormatPercent(Percent(stats.landlord_wins, stats.landlord_games))
             << " | " << FormatPercent(Percent(stats.farmer_wins, stats.farmer_games))
             << " |\n";
    }
  }
}

}  // namespace

int main() {
  try {
    Require(landlords::ai::OnnxRuntimeAvailable(), "onnx runtime is not enabled");
    const auto candidates = BuildCandidates();
    const int games_per_seat = LoadGamesPerSeat();

    std::map<std::pair<std::string, std::string>, PairwiseResult> pairwise;
    for (const auto& candidate : candidates) {
      for (const auto& opponent : candidates) {
        if (candidate.key == opponent.key) {
          continue;
        }
        std::cout << "[benchmark] " << candidate.label << " vs " << opponent.label << std::endl;
        pairwise.emplace(std::make_pair(candidate.key, opponent.key),
                         PairwiseResult{
                             .stats = SimulateOrderedMatchup(candidate, opponent, games_per_seat),
                         });
      }
    }

    const auto report_path =
        std::filesystem::path("reports/strategy_benchmark.md");
    WriteReport(report_path, candidates, pairwise, games_per_seat);
    std::cout << "strategy benchmark written to " << report_path.string() << std::endl;
    return 0;
  } catch (const std::exception& exception) {
    std::cerr << "strategy benchmark failed: " << exception.what() << std::endl;
    return 1;
  }
}
