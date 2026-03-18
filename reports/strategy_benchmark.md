# Dou Dizhu Strategy Benchmark

## Methodology

- Seat-controlled benchmark: one controlled seat uses the primary strategy, the other two seats use the opponent strategy.
- Games per seat matchup: `200`.
- Total games per primary/opponent pair: `600`.
- This is stricter than a simple 1v1 win-rate comparison because 斗地�?has asymmetric 2v1 cooperation.

## Overall Ranking

| Rank | Candidate | Games | Avg Score | Win Rate | Landlord Win | Farmer Win |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | DouZero-WP | 1800 | 1.54 | 65.6% | 76.5% | 60.2% |
| 2 | SL | 1800 | 0.95 | 59.3% | 64.3% | 56.7% |
| 3 | DouZero-ADP | 1800 | -0.26 | 46.3% | 41.1% | 48.7% |
| 4 | Heuristic | 1800 | -1.60 | 33.8% | 27.7% | 36.8% |

## Pairwise Matrix

| Candidate | Heuristic | SL | DouZero-ADP | DouZero-WP |
| --- | ---: | ---: | ---: | ---: |
| Heuristic | - | -2.13 / 26.8% | -0.19 / 53.3% | -2.48 / 21.2% |
| SL | 2.55 / 77.3% | - | 1.04 / 61.8% | -0.75 / 38.7% |
| DouZero-ADP | 0.37 / 58.2% | -0.46 / 45.7% | - | -0.68 / 35.0% |
| DouZero-WP | 2.41 / 72.8% | 0.72 / 55.3% | 1.49 / 68.7% | - |

## Detailed Matchups

| Primary | Opponent Team | Games | Avg Score | Win Rate | Landlord Win | Farmer Win |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Heuristic | SL | 600 | -2.13 | 26.8% | 18.3% | 31.2% |
| Heuristic | DouZero-ADP | 600 | -0.19 | 53.3% | 38.0% | 61.8% |
| Heuristic | DouZero-WP | 600 | -2.48 | 21.2% | 26.0% | 19.1% |
| SL | Heuristic | 600 | 2.55 | 77.3% | 82.9% | 74.6% |
| SL | DouZero-ADP | 600 | 1.04 | 61.8% | 62.7% | 61.4% |
| SL | DouZero-WP | 600 | -0.75 | 38.7% | 47.5% | 34.2% |
| DouZero-ADP | Heuristic | 600 | 0.37 | 58.2% | 45.2% | 64.1% |
| DouZero-ADP | SL | 600 | -0.46 | 45.7% | 44.1% | 46.5% |
| DouZero-ADP | DouZero-WP | 600 | -0.68 | 35.0% | 33.3% | 35.7% |
| DouZero-WP | Heuristic | 600 | 2.41 | 72.8% | 86.4% | 66.1% |
| DouZero-WP | SL | 600 | 0.72 | 55.3% | 70.4% | 47.6% |
| DouZero-WP | DouZero-ADP | 600 | 1.49 | 68.7% | 72.7% | 66.7% |
