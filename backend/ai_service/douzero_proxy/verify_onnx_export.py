from __future__ import annotations

import argparse
import json
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from adapter import DouZeroAdapter, ROOT_DIR
from generated import landlords_pb2


BASELINE_TO_ONNX = {
    "douzero_ADP": "douzero_ADP",
    "douzero_WP": "douzero_WP",
    "sl": "sl",
}


@dataclass(frozen=True)
class Case:
    name: str
    snapshot: landlords_pb2.RoomSnapshot


def make_card(card_id: str, rank: str, suit: str, value: int) -> landlords_pb2.Card:
    card = landlords_pb2.Card()
    card.id = card_id
    card.rank = rank
    card.suit = suit
    card.value = value
    return card


def add_action(
    snapshot: landlords_pb2.RoomSnapshot,
    *,
    player_id: str,
    action_type: int,
    pattern: str,
    cards: list[tuple[str, str, str, int]] | None = None,
) -> None:
    action = snapshot.recent_actions.add()
    action.player_id = player_id
    action.action_type = action_type
    action.pattern = pattern
    for card_id, rank, suit, value in cards or []:
        action.cards.append(make_card(card_id, rank, suit, value))


def build_players(
    snapshot: landlords_pb2.RoomSnapshot,
    *,
    landlord_cards_left: int,
    down_cards_left: int,
    up_cards_left: int,
) -> None:
    landlord = snapshot.players.add()
    landlord.player_id = "p_landlord"
    landlord.display_name = "Landlord"
    landlord.is_bot = True
    landlord.role = landlords_pb2.PLAYER_ROLE_LANDLORD
    landlord.cards_left = landlord_cards_left

    down = snapshot.players.add()
    down.player_id = "p_down"
    down.display_name = "Farmer Down"
    down.is_bot = True
    down.role = landlords_pb2.PLAYER_ROLE_FARMER
    down.cards_left = down_cards_left

    up = snapshot.players.add()
    up.player_id = "p_up"
    up.display_name = "Farmer Up"
    up.is_bot = True
    up.role = landlords_pb2.PLAYER_ROLE_FARMER
    up.cards_left = up_cards_left


def build_cases() -> list[Case]:
    cases: list[Case] = []

    landlord_open = landlords_pb2.RoomSnapshot()
    landlord_open.room_id = "parity_landlord_open"
    landlord_open.phase = landlords_pb2.ROOM_PHASE_PLAYING
    landlord_open.mode = landlords_pb2.MATCH_MODE_VS_BOT
    landlord_open.current_turn_player_id = "p_landlord"
    build_players(
        landlord_open,
        landlord_cards_left=20,
        down_cards_left=17,
        up_cards_left=17,
    )
    for card in [
        ("s1", "3", "S", 3),
        ("s2", "3", "H", 3),
        ("s3", "4", "S", 4),
        ("s4", "4", "H", 4),
        ("s5", "5", "S", 5),
        ("s6", "5", "H", 5),
        ("s7", "6", "S", 6),
        ("s8", "6", "H", 6),
        ("s9", "7", "S", 7),
        ("s10", "7", "H", 7),
        ("s11", "8", "S", 8),
        ("s12", "8", "H", 8),
        ("s13", "9", "S", 9),
        ("s14", "9", "H", 9),
        ("s15", "10", "S", 10),
        ("s16", "J", "S", 11),
        ("s17", "Q", "S", 12),
        ("s18", "K", "S", 13),
        ("s19", "A", "S", 14),
        ("s20", "2", "S", 15),
    ]:
        landlord_open.self_cards.append(make_card(*card))
    for card in [
        ("l1", "Q", "D", 12),
        ("l2", "K", "D", 13),
        ("l3", "A", "D", 14),
    ]:
        landlord_open.landlord_cards.append(make_card(*card))
    cases.append(Case("landlord_open", landlord_open))

    down_response = landlords_pb2.RoomSnapshot()
    down_response.room_id = "parity_down_response"
    down_response.phase = landlords_pb2.ROOM_PHASE_PLAYING
    down_response.mode = landlords_pb2.MATCH_MODE_VS_BOT
    down_response.current_turn_player_id = "p_down"
    build_players(
        down_response,
        landlord_cards_left=16,
        down_cards_left=17,
        up_cards_left=17,
    )
    for card in [
        ("d1", "5", "S", 5),
        ("d2", "5", "H", 5),
        ("d3", "6", "S", 6),
        ("d4", "7", "S", 7),
        ("d5", "7", "H", 7),
        ("d6", "8", "S", 8),
        ("d7", "8", "H", 8),
        ("d8", "9", "S", 9),
        ("d9", "9", "H", 9),
        ("d10", "10", "S", 10),
        ("d11", "J", "S", 11),
        ("d12", "Q", "S", 12),
        ("d13", "Q", "H", 12),
        ("d14", "K", "S", 13),
        ("d15", "A", "S", 14),
        ("d16", "2", "S", 15),
        ("d17", "SJ", "J", 16),
    ]:
        down_response.self_cards.append(make_card(*card))
    add_action(
        down_response,
        player_id="p_landlord",
        action_type=landlords_pb2.ACTION_TYPE_PLAY,
        pattern="pair",
        cards=[("a1", "4", "S", 4), ("a2", "4", "H", 4)],
    )
    cases.append(Case("landlord_down_response", down_response))

    up_response = landlords_pb2.RoomSnapshot()
    up_response.room_id = "parity_up_response"
    up_response.phase = landlords_pb2.ROOM_PHASE_PLAYING
    up_response.mode = landlords_pb2.MATCH_MODE_VS_BOT
    up_response.current_turn_player_id = "p_up"
    build_players(
        up_response,
        landlord_cards_left=15,
        down_cards_left=16,
        up_cards_left=17,
    )
    for card in [
        ("u1", "3", "S", 3),
        ("u2", "4", "S", 4),
        ("u3", "4", "H", 4),
        ("u4", "5", "S", 5),
        ("u5", "6", "S", 6),
        ("u6", "7", "S", 7),
        ("u7", "8", "S", 8),
        ("u8", "8", "H", 8),
        ("u9", "9", "S", 9),
        ("u10", "9", "H", 9),
        ("u11", "10", "S", 10),
        ("u12", "J", "S", 11),
        ("u13", "Q", "S", 12),
        ("u14", "K", "S", 13),
        ("u15", "A", "S", 14),
        ("u16", "2", "S", 15),
        ("u17", "BJ", "J", 17),
    ]:
        up_response.self_cards.append(make_card(*card))
    add_action(
        up_response,
        player_id="p_landlord",
        action_type=landlords_pb2.ACTION_TYPE_PLAY,
        pattern="single",
        cards=[("b1", "7", "D", 7)],
    )
    add_action(
        up_response,
        player_id="p_down",
        action_type=landlords_pb2.ACTION_TYPE_PASS,
        pattern="pass",
    )
    cases.append(Case("landlord_up_response", up_response))

    reset_lead = landlords_pb2.RoomSnapshot()
    reset_lead.room_id = "parity_reset_lead"
    reset_lead.phase = landlords_pb2.ROOM_PHASE_PLAYING
    reset_lead.mode = landlords_pb2.MATCH_MODE_VS_BOT
    reset_lead.current_turn_player_id = "p_down"
    build_players(
        reset_lead,
        landlord_cards_left=13,
        down_cards_left=17,
        up_cards_left=15,
    )
    for card in [
        ("r1", "3", "S", 3),
        ("r2", "3", "H", 3),
        ("r3", "4", "S", 4),
        ("r4", "5", "S", 5),
        ("r5", "5", "H", 5),
        ("r6", "6", "S", 6),
        ("r7", "7", "S", 7),
        ("r8", "8", "S", 8),
        ("r9", "9", "S", 9),
        ("r10", "10", "S", 10),
        ("r11", "J", "S", 11),
        ("r12", "J", "H", 11),
        ("r13", "Q", "S", 12),
        ("r14", "K", "S", 13),
        ("r15", "A", "S", 14),
        ("r16", "2", "S", 15),
        ("r17", "SJ", "J", 16),
    ]:
        reset_lead.self_cards.append(make_card(*card))
    add_action(
        reset_lead,
        player_id="p_landlord",
        action_type=landlords_pb2.ACTION_TYPE_PLAY,
        pattern="bid_3",
    )
    add_action(
        reset_lead,
        player_id="p_down",
        action_type=landlords_pb2.ACTION_TYPE_PASS,
        pattern="bid_pass",
    )
    add_action(
        reset_lead,
        player_id="p_up",
        action_type=landlords_pb2.ACTION_TYPE_PLAY,
        pattern="managed_on",
    )
    add_action(
        reset_lead,
        player_id="p_landlord",
        action_type=landlords_pb2.ACTION_TYPE_PLAY,
        pattern="single",
        cards=[("c1", "8", "D", 8)],
    )
    add_action(
        reset_lead,
        player_id="p_down",
        action_type=landlords_pb2.ACTION_TYPE_PASS,
        pattern="pass",
    )
    add_action(
        reset_lead,
        player_id="p_up",
        action_type=landlords_pb2.ACTION_TYPE_PASS,
        pattern="pass",
    )
    cases.append(Case("reset_after_two_passes", reset_lead))

    return cases


def parse_cli_output(stdout: str) -> tuple[str, list[str]]:
    values: dict[str, str] = {}
    for line in stdout.splitlines():
        if "=" not in line:
            continue
        key, raw = line.split("=", 1)
        values[key.strip()] = raw.strip()
    kind = values.get("kind", "")
    card_ids = [item for item in values.get("card_ids", "").split(",") if item]
    return kind, sorted(card_ids)


def card_ids_to_env_values(
    snapshot: landlords_pb2.RoomSnapshot, card_ids: list[str]
) -> list[int]:
    by_id = {card.id: card for card in snapshot.self_cards}
    values: list[int] = []
    for card_id in card_ids:
        card = by_id.get(card_id)
        if card is None:
            raise KeyError(f"Unknown card id in decision: {card_id}")
        values.append(
            {
                "3": 3,
                "4": 4,
                "5": 5,
                "6": 6,
                "7": 7,
                "8": 8,
                "9": 9,
                "10": 10,
                "J": 11,
                "Q": 12,
                "K": 13,
                "A": 14,
                "2": 17,
                "SJ": 20,
                "BJ": 30,
            }[card.rank]
        )
    return sorted(values)


def validate_manifest(baseline_dir: Path, onnx_dir: Path) -> None:
    manifest_path = onnx_dir / "manifest.json"
    if not manifest_path.exists():
        raise FileNotFoundError(f"Missing manifest: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    resolved_baseline = str(baseline_dir.resolve())
    if manifest.get("baseline_dir") != resolved_baseline:
        raise ValueError(
            f"Manifest baseline mismatch for {onnx_dir}: "
            f"{manifest.get('baseline_dir')} != {resolved_baseline}"
        )

    expected_widths = {"landlord": 373, "landlord_up": 484, "landlord_down": 484}
    roles = manifest.get("roles", {})
    for role, width in expected_widths.items():
        info = roles.get(role)
        if not info:
            raise ValueError(f"Manifest missing role '{role}' in {manifest_path}")
        checkpoint = Path(info["checkpoint"])
        onnx_path = Path(info["onnx"])
        if checkpoint.parent.resolve() != baseline_dir.resolve():
            raise ValueError(f"Checkpoint parent mismatch for {role}: {checkpoint}")
        if checkpoint.stem != role:
            raise ValueError(f"Checkpoint role mismatch for {role}: {checkpoint.name}")
        if onnx_path.parent.resolve() != onnx_dir.resolve():
            raise ValueError(f"ONNX parent mismatch for {role}: {onnx_path}")
        if onnx_path.stem != role:
            raise ValueError(f"ONNX role mismatch for {role}: {onnx_path.name}")
        if int(info["x_width"]) != width:
            raise ValueError(f"x_width mismatch for {role}: {info['x_width']} != {width}")


def run_case(
    *,
    case: Case,
    adapter: DouZeroAdapter,
    cli_path: Path,
    onnx_dir: Path,
) -> tuple[tuple[str, list[int]], tuple[str, list[int]]]:
    python_response = adapter.choose_move(case.snapshot)
    python_result = (
        "pass" if len(python_response.card_ids) == 0 else "play",
        card_ids_to_env_values(case.snapshot, list(python_response.card_ids)),
    )

    with tempfile.TemporaryDirectory(prefix="landlords_onnx_verify_") as temp_dir:
        snapshot_path = Path(temp_dir) / f"{case.name}.pb"
        snapshot_path.write_bytes(case.snapshot.SerializeToString())
        completed = subprocess.run(
            [
                str(cli_path),
                "--model-dir",
                str(onnx_dir),
                "--snapshot",
                str(snapshot_path),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    cli_result = parse_cli_output(completed.stdout)
    return (
        python_result,
        (cli_result[0], card_ids_to_env_values(case.snapshot, cli_result[1])),
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify that exported ONNX models make the same decision as the original DouZero checkpoints."
    )
    parser.add_argument(
        "--cli-path",
        type=Path,
        default=ROOT_DIR / "backend" / "server" / "build-vs" / "Debug" / "landlords_onnx_decision_cli.exe",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    cli_path = args.cli_path.resolve()
    if not cli_path.exists():
        raise FileNotFoundError(f"Missing ONNX CLI executable: {cli_path}")

    cases = build_cases()
    mismatches: list[str] = []
    checked = 0

    for baseline_name, onnx_name in BASELINE_TO_ONNX.items():
        baseline_dir = (ROOT_DIR / "third_party" / "baselines" / baseline_name).resolve()
        onnx_dir = (ROOT_DIR / "backend" / "ai_models" / "onnx" / onnx_name).resolve()
        validate_manifest(baseline_dir, onnx_dir)
        adapter = DouZeroAdapter(baseline_dir)
        print(f"[verify] baseline={baseline_name} onnx={onnx_name}")
        for case in cases:
            python_result, cli_result = run_case(
                case=case,
                adapter=adapter,
                cli_path=cli_path,
                onnx_dir=onnx_dir,
            )
            checked += 1
            if python_result != cli_result:
                mismatches.append(
                    f"{baseline_name}:{case.name} python={python_result} onnx={cli_result}"
                )
                print(f"  FAIL {case.name}: python={python_result} onnx={cli_result}")
            else:
                print(f"  PASS {case.name}: {python_result}")

    if mismatches:
        print("\n[verify] mismatches detected:")
        for item in mismatches:
            print(f"  - {item}")
        return 1

    print(f"\n[verify] all parity checks passed ({checked} cases)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
