#include "landlords/game/bid_strategy.h"

#include <algorithm>
#include <array>
#include <map>

namespace landlords::game {

namespace {

using Counts = std::array<int, 18>;

struct RunInfo {
  int start = 0;
  int length = 0;

  [[nodiscard]] bool valid() const {
    return length > 0;
  }

  [[nodiscard]] int end() const {
    return start + length - 1;
  }
};

struct StructureProfile {
  int estimated_turns = 0;
  int airplane_runs = 0;
  int airplane_chain = 0;
  int straight_pair_runs = 0;
  int straight_pair_chain = 0;
  int straight_runs = 0;
  int straight_chain = 0;
  int triples = 0;
  int triples_with_pair = 0;
  int triples_with_single = 0;
  int bombs = 0;
  bool rocket = false;
  int leftover_pairs = 0;
  int leftover_singles = 0;
  int leftover_low_singles = 0;
};

Counts BuildCounts(const std::vector<core::Card>& hand) {
  Counts counts{};
  for (const auto& card : hand) {
    if (card.value >= 0 && card.value < static_cast<int>(counts.size())) {
      ++counts[card.value];
    }
  }
  return counts;
}

RunInfo FindLongestRun(const Counts& counts, int min_count, int min_length) {
  RunInfo best;
  int current_start = -1;
  int current_length = 0;

  for (int value = 3; value <= 14; ++value) {
    if (counts[value] >= min_count) {
      if (current_start < 0) {
        current_start = value;
        current_length = 1;
      } else {
        ++current_length;
      }
      continue;
    }

    if (current_length >= min_length &&
        (current_length > best.length ||
         (current_length == best.length && value - 1 > best.end()))) {
      best = RunInfo{.start = current_start, .length = current_length};
    }
    current_start = -1;
    current_length = 0;
  }

  if (current_length >= min_length &&
      (current_length > best.length ||
       (current_length == best.length && current_start + current_length - 1 > best.end()))) {
    best = RunInfo{.start = current_start, .length = current_length};
  }
  return best;
}

void ConsumeRun(Counts& counts, const RunInfo& run, int consume_count) {
  for (int value = run.start; value <= run.end(); ++value) {
    counts[value] -= consume_count;
  }
}

bool IsExcluded(int value, int excluded_start, int excluded_end) {
  return excluded_start >= 0 && value >= excluded_start && value <= excluded_end;
}

bool TakeAttachments(Counts& counts,
                     int groups_needed,
                     int cards_per_group,
                     int excluded_start = -1,
                     int excluded_end = -1) {
  if (groups_needed <= 0) {
    return true;
  }

  struct Candidate {
    int priority = 0;
    int value = 0;
  };

  std::vector<Candidate> candidates;
  candidates.reserve(15);
  for (int value = 3; value <= 17; ++value) {
    if (IsExcluded(value, excluded_start, excluded_end) || counts[value] < cards_per_group) {
      continue;
    }

    int priority = 0;
    if (cards_per_group == 1) {
      if (counts[value] == 1) {
        priority = 0;
      } else if (counts[value] == 2) {
        priority = 4;
      } else if (counts[value] == 3) {
        priority = 8;
      } else {
        priority = 14;
      }
      if (value >= 15) {
        priority += 18;
      } else if (value >= 13) {
        priority += 8;
      }
    } else {
      if (counts[value] == 2) {
        priority = 0;
      } else if (counts[value] == 3) {
        priority = 6;
      } else {
        priority = 16;
      }
      if (value >= 15) {
        priority += 20;
      } else if (value >= 13) {
        priority += 8;
      }
    }

    candidates.push_back(Candidate{.priority = priority, .value = value});
  }

  std::sort(candidates.begin(), candidates.end(), [](const Candidate& left, const Candidate& right) {
    if (left.priority != right.priority) {
      return left.priority < right.priority;
    }
    return left.value < right.value;
  });

  if (static_cast<int>(candidates.size()) < groups_needed) {
    return false;
  }

  for (int index = 0; index < groups_needed; ++index) {
    counts[candidates[static_cast<std::size_t>(index)].value] -= cards_per_group;
  }
  return true;
}

StructureProfile AnalyzeStructure(const Counts& original_counts) {
  Counts counts = original_counts;
  StructureProfile profile;

  while (true) {
    const auto run = FindLongestRun(counts, 3, 2);
    if (!run.valid()) {
      break;
    }

    ConsumeRun(counts, run, 3);
    if (!TakeAttachments(counts, run.length, 2, run.start, run.end())) {
      TakeAttachments(counts, run.length, 1, run.start, run.end());
    }

    ++profile.airplane_runs;
    profile.airplane_chain += run.length;
    ++profile.estimated_turns;
  }

  while (true) {
    const auto run = FindLongestRun(counts, 2, 3);
    if (!run.valid()) {
      break;
    }

    ConsumeRun(counts, run, 2);
    ++profile.straight_pair_runs;
    profile.straight_pair_chain += run.length;
    ++profile.estimated_turns;
  }

  while (true) {
    const auto run = FindLongestRun(counts, 1, 5);
    if (!run.valid()) {
      break;
    }

    ConsumeRun(counts, run, 1);
    ++profile.straight_runs;
    profile.straight_chain += run.length;
    ++profile.estimated_turns;
  }

  if (counts[16] > 0 && counts[17] > 0) {
    --counts[16];
    --counts[17];
    profile.rocket = true;
    ++profile.estimated_turns;
  }

  for (int value = 3; value <= 15; ++value) {
    if (counts[value] == 4) {
      counts[value] = 0;
      ++profile.bombs;
      ++profile.estimated_turns;
    }
  }

  for (int value = 3; value <= 17; ++value) {
    while (counts[value] >= 3) {
      counts[value] -= 3;
      ++profile.triples;
      if (TakeAttachments(counts, 1, 2, value, value)) {
        ++profile.triples_with_pair;
      } else if (TakeAttachments(counts, 1, 1, value, value)) {
        ++profile.triples_with_single;
      }
      ++profile.estimated_turns;
    }
  }

  for (int value = 3; value <= 17; ++value) {
    while (counts[value] >= 2) {
      counts[value] -= 2;
      ++profile.leftover_pairs;
      ++profile.estimated_turns;
    }
    while (counts[value] >= 1) {
      --counts[value];
      ++profile.leftover_singles;
      if (value <= 10) {
        ++profile.leftover_low_singles;
      }
      ++profile.estimated_turns;
    }
  }

  return profile;
}

int ControlScore(const Counts& counts) {
  int score = 0;
  score += counts[17] * 15;
  score += counts[16] * 12;
  score += counts[15] * 8;
  score += counts[14] * 5;
  score += counts[13] * 2;
  score += counts[12];

  if (counts[16] > 0 && counts[17] > 0) {
    score += 10;
  }
  if (counts[15] >= 2) {
    score += 6;
  }
  if (counts[14] >= 2) {
    score += 4;
  }
  return score;
}

int DistributionScore(const Counts& counts) {
  int score = 0;
  for (int value = 3; value <= 17; ++value) {
    if (counts[value] == 4) {
      score += value >= 13 ? 12 : 9;
    } else if (counts[value] == 3) {
      score += value >= 12 ? 7 : 5;
    } else if (counts[value] == 2) {
      score += value >= 13 ? 5 : 3;
    } else if (counts[value] == 1) {
      if (value <= 8) {
        score -= 3;
      } else if (value <= 10) {
        score -= 1;
      }
    }
  }
  return score;
}

int StructureScore(const StructureProfile& profile) {
  int score = 0;
  score += profile.airplane_chain * 9;
  score += profile.airplane_runs * 8;
  score += profile.straight_pair_chain * 5;
  score += profile.straight_pair_runs * 4;
  score += profile.straight_chain * 2;
  score += profile.straight_runs;
  score += profile.triples * 5;
  score += profile.triples_with_pair * 5;
  score += profile.triples_with_single * 2;
  score += profile.bombs * 14;
  if (profile.rocket) {
    score += 18;
  }
  score -= profile.leftover_low_singles * 4;
  score -= std::max(0, profile.leftover_singles - 3) * 2;
  return score;
}

int TurnScore(int estimated_turns) {
  if (estimated_turns <= 4) {
    return 28;
  }
  if (estimated_turns == 5) {
    return 20;
  }
  if (estimated_turns == 6) {
    return 12;
  }
  if (estimated_turns == 7) {
    return 4;
  }
  if (estimated_turns == 8) {
    return -6;
  }
  return -12 - (estimated_turns - 9) * 6;
}

}  // namespace

int SuggestBidLevel(const std::vector<core::Card>& hand) {
  const Counts counts = BuildCounts(hand);
  const StructureProfile profile = AnalyzeStructure(counts);
  const int control_score = ControlScore(counts);

  int raw_score = 0;
  raw_score += control_score;
  raw_score += DistributionScore(counts);
  raw_score += StructureScore(profile);
  raw_score += TurnScore(profile.estimated_turns);

  if (profile.airplane_chain >= 2 && profile.leftover_singles <= 2) {
    raw_score += 8;
  }
  if (profile.bombs >= 1 && profile.estimated_turns <= 6) {
    raw_score += 6;
  }
  if (profile.leftover_singles <= 2) {
    raw_score += 4;
  }

  // A naked straight with many loose kickers looks pretty, but it is usually
  // a weak landlord hand unless it also has real control cards or follow-up structure.
  if (profile.straight_runs > 0 &&
      profile.straight_pair_runs == 0 &&
      profile.airplane_runs == 0 &&
      profile.triples == 0 &&
      profile.bombs == 0 &&
      !profile.rocket &&
      profile.leftover_singles >= 4 &&
      control_score < 14) {
    raw_score -= 18;
  }

  if (raw_score >= 78 ||
      (profile.estimated_turns <= 4 && raw_score >= 64) ||
      (profile.estimated_turns <= 5 && profile.bombs >= 1 && raw_score >= 60)) {
    return 3;
  }
  if (raw_score >= 52 ||
      (profile.estimated_turns <= 5 && raw_score >= 44) ||
      (profile.estimated_turns <= 6 && ControlScore(counts) >= 26)) {
    return 2;
  }
  if (raw_score >= 30 ||
      (profile.estimated_turns <= 6 && raw_score >= 24) ||
      (profile.estimated_turns <= 5 && ControlScore(counts) >= 18)) {
    return 1;
  }
  return 0;
}

int ChooseBidAction(const std::vector<core::Card>& hand,
                    int current_highest_bid,
                    landlords::protocol::BotDifficulty difficulty) {
  if (current_highest_bid >= 3) {
    return 0;
  }

  int suggested = SuggestBidLevel(hand);
  switch (difficulty) {
    case landlords::protocol::BOT_DIFFICULTY_EASY:
      suggested = std::max(0, suggested - 1);
      break;
    case landlords::protocol::BOT_DIFFICULTY_HARD:
      suggested = std::min(3, suggested + 1);
      break;
    case landlords::protocol::BOT_DIFFICULTY_NORMAL:
    case landlords::protocol::BOT_DIFFICULTY_UNSPECIFIED:
      break;
  }
  if (current_highest_bid <= 0) {
    return suggested;
  }
  if (current_highest_bid == 1) {
    return suggested >= 2 ? suggested : 0;
  }
  return suggested == 3 ? 3 : 0;
}

}  // namespace landlords::game
