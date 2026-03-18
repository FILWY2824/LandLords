from __future__ import annotations

import os
import sys
import importlib.util
import threading
import time
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

ROOT_DIR = Path(__file__).resolve().parents[3]
DOUZERO_ROOT = Path(
    os.environ.get("LANDLORDS_DOUZERO_ROOT", ROOT_DIR / "third_party" / "DouZero")
).resolve()
if str(DOUZERO_ROOT) not in sys.path:
    sys.path.insert(0, str(DOUZERO_ROOT))

from douzero.env import move_detector as md  # type: ignore
from douzero.env import move_selector as ms  # type: ignore
from douzero.env.env import get_obs  # type: ignore
from douzero.env.game import InfoSet  # type: ignore
from douzero.env.move_generator import MovesGener  # type: ignore
import numpy as np
import torch

from generated import landlords_pb2
from logging_utils import get_logger

ROLE_FILES = {
    "landlord": "landlord.ckpt",
    "landlord_up": "landlord_up.ckpt",
    "landlord_down": "landlord_down.ckpt",
}

RANK_TO_ENV_VALUE = {
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
}

FULL_DECK = [value for value in range(3, 15) for _ in range(4)] + [17] * 4 + [20, 30]
BOMBS = {tuple([value] * 4) for value in range(3, 18)} | {(20, 30)}
ROLE_X_WIDTH = {
    "landlord": 373,
    "landlord_up": 484,
    "landlord_down": 484,
}


def _env_flag(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() not in {"0", "false", "off", "no"}


def _resolve_device() -> str:
    raw = os.environ.get("LANDLORDS_DOUZERO_DEVICE", "cpu").strip().lower()
    if raw == "auto":
        return "cuda:0" if torch.cuda.is_available() else "cpu"
    if raw in {"cuda", "gpu"}:
        return "cuda:0" if torch.cuda.is_available() else "cpu"
    if raw.startswith("cuda:"):
        return raw if torch.cuda.is_available() else "cpu"
    return "cpu"


def _configure_torch_runtime(device: str) -> None:
    if device == "cpu":
        default_threads = min(max((os.cpu_count() or 4) // 2, 1), 4)
        threads = int(os.environ.get("LANDLORDS_DOUZERO_NUM_THREADS", default_threads))
        torch.set_num_threads(max(1, threads))


@dataclass(frozen=True)
class PlayerSeat:
    player_id: str
    position: str
    cards_left: int


class DouZeroAdapter:
    def __init__(self, baseline_dir: Path | None = None) -> None:
        self._logger = get_logger("douzero_proxy.adapter")
        self._baseline_dir = (baseline_dir or self._default_baseline_dir()).resolve()
        self._device = _resolve_device()
        self._inference_lock = threading.Lock()
        self._agents: dict[str, _LoadedAgent] = {}
        _configure_torch_runtime(self._device)
        self._validate_model_files()

        self._logger.info(
            "adapter ready baseline=%s device=%s preload=%s warmup=%s",
            self._baseline_dir,
            self._device,
            _env_flag("LANDLORDS_DOUZERO_PRELOAD", True),
            _env_flag("LANDLORDS_DOUZERO_WARMUP", True),
        )
        if _env_flag("LANDLORDS_DOUZERO_PRELOAD", True):
            self._preload_agents()
        if _env_flag("LANDLORDS_DOUZERO_WARMUP", True):
            self._warmup_agents()

    @property
    def baseline_dir(self) -> Path:
        return self._baseline_dir

    @property
    def device(self) -> str:
        return self._device

    @property
    def loaded_positions(self) -> list[str]:
        return sorted(self._agents.keys())

    def choose_move(
        self, snapshot: landlords_pb2.RoomSnapshot
    ) -> landlords_pb2.PlayCardsRequest:
        response = landlords_pb2.PlayCardsRequest()
        response.room_id = snapshot.room_id

        if snapshot.phase != landlords_pb2.ROOM_PHASE_PLAYING:
            return response

        acting_player_id = snapshot.current_turn_player_id
        seats = self._build_seats(snapshot)
        if acting_player_id not in seats:
            return response

        infoset = self._build_infoset(snapshot, seats[acting_player_id].position, seats)
        started = time.perf_counter()
        with self._inference_lock:
            action = self._agent_for(seats[acting_player_id].position).act(infoset)
        self._logger.debug(
            "inference room=%s turn=%s role=%s legal_actions=%d elapsed_ms=%.1f",
            snapshot.room_id,
            acting_player_id,
            seats[acting_player_id].position,
            len(infoset.legal_actions),
            (time.perf_counter() - started) * 1000.0,
        )
        for card_id in self._match_card_ids(snapshot.self_cards, action):
            response.card_ids.append(card_id)
        return response

    def _default_baseline_dir(self) -> Path:
        return Path(
            os.environ.get(
                "LANDLORDS_DOUZERO_BASELINE_DIR",
                ROOT_DIR / "third_party" / "baselines" / "douzero_ADP",
            )
        )

    def _validate_model_files(self) -> None:
        missing = [
            filename
            for filename in ROLE_FILES.values()
            if not (self._baseline_dir / filename).exists()
        ]
        if missing:
            missing_text = ", ".join(missing)
            raise FileNotFoundError(
                f"Missing DouZero model files in {self._baseline_dir}: {missing_text}"
            )

    def _agent_for(self, position: str) -> "_LoadedAgent":
        if position not in self._agents:
            self._agents[position] = _LoadedAgent(
                position,
                str((self._baseline_dir / ROLE_FILES[position]).resolve()),
                self._device,
                self._logger,
            )
        return self._agents[position]

    def _preload_agents(self) -> None:
        for position in ROLE_FILES:
            self._agent_for(position)
        self._logger.info("preloaded roles=%s", ",".join(self.loaded_positions))

    def _warmup_agents(self) -> None:
        for position in ROLE_FILES:
            self._agent_for(position).warmup()
        self._logger.info("warmup complete roles=%s", ",".join(self.loaded_positions))

    def _build_seats(
        self, snapshot: landlords_pb2.RoomSnapshot
    ) -> dict[str, PlayerSeat]:
        landlord_index = -1
        for index, player in enumerate(snapshot.players):
            if player.role == landlords_pb2.PLAYER_ROLE_LANDLORD:
                landlord_index = index
                break
        if landlord_index < 0:
            raise ValueError("No landlord seat found in snapshot")

        ordered = list(snapshot.players)
        mapping = {
            ordered[landlord_index].player_id: "landlord",
            ordered[(landlord_index + 1) % len(ordered)].player_id: "landlord_down",
            ordered[(landlord_index + 2) % len(ordered)].player_id: "landlord_up",
        }
        return {
            player.player_id: PlayerSeat(
                player_id=player.player_id,
                position=mapping[player.player_id],
                cards_left=player.cards_left,
            )
            for player in ordered
        }

    def _build_infoset(
        self,
        snapshot: landlords_pb2.RoomSnapshot,
        position: str,
        seats: dict[str, PlayerSeat],
    ) -> InfoSet:
        infoset = InfoSet(position)
        action_seq, last_move_dict, played_cards, last_pid, bomb_num = self._build_history(
            snapshot, seats
        )
        infoset.player_hand_cards = sorted(
            self._cards_to_env_values(snapshot.self_cards)
        )
        infoset.num_cards_left_dict = {
            seat.position: seat.cards_left for seat in seats.values()
        }
        infoset.three_landlord_cards = sorted(
            self._cards_to_env_values(snapshot.landlord_cards)
        )
        infoset.card_play_action_seq = action_seq
        infoset.other_hand_cards = self._build_other_hand_cards(snapshot)
        infoset.last_move = self._current_lead_move(action_seq)
        infoset.last_two_moves = self._last_two_moves(action_seq)
        infoset.last_move_dict = last_move_dict
        infoset.played_cards = played_cards
        infoset.last_pid = last_pid
        infoset.bomb_num = bomb_num
        infoset.legal_actions = self._build_legal_actions(infoset.player_hand_cards, action_seq)
        infoset.all_handcards = {position: infoset.player_hand_cards}
        return infoset

    def _build_other_hand_cards(
        self, snapshot: landlords_pb2.RoomSnapshot
    ) -> list[int]:
        remaining = Counter(FULL_DECK)
        for value in self._cards_to_env_values(snapshot.self_cards):
            remaining[value] -= 1
        for action in snapshot.recent_actions:
            for value in self._cards_to_env_values(action.cards):
                remaining[value] -= 1

        cards: list[int] = []
        for value in sorted(remaining.elements()):
            cards.append(value)
        return cards

    def _build_history(
        self,
        snapshot: landlords_pb2.RoomSnapshot,
        seats: dict[str, PlayerSeat],
    ) -> tuple[list[list[int]], dict[str, list[int]], dict[str, list[int]], str, int]:
        action_seq: list[list[int]] = []
        last_move_dict = {position: [] for position in ROLE_FILES}
        played_cards = {position: [] for position in ROLE_FILES}
        last_pid = "landlord"
        bomb_num = 0

        for action in snapshot.recent_actions:
            if action.player_id not in seats:
                continue
            if self._is_system_action(action):
                continue
            move = self._action_to_move(action)
            if move is None:
                continue
            move = sorted(move)
            action_seq.append(move)
            position = seats[action.player_id].position
            last_move_dict[position] = move
            if move:
                played_cards[position].extend(move)
                last_pid = position
                if tuple(move) in BOMBS:
                    bomb_num += 1

        return action_seq, last_move_dict, played_cards, last_pid, bomb_num

    def _action_to_move(
        self, action: landlords_pb2.TableAction
    ) -> list[int] | None:
        if action.action_type == landlords_pb2.ACTION_TYPE_PASS:
            return []
        if action.action_type != landlords_pb2.ACTION_TYPE_PLAY:
            return None
        if len(action.cards) == 0:
            return None
        return self._cards_to_env_values(action.cards)

    def _build_legal_actions(
        self, hand_cards: list[int], action_seq: list[list[int]]
    ) -> list[list[int]]:
        move_generator = MovesGener(hand_cards)
        rival_move = self._current_lead_move(action_seq)

        rival_type = md.get_move_type(rival_move)
        rival_move_type = rival_type["type"]
        rival_move_len = rival_type.get("len", 1)

        if rival_move_type == md.TYPE_0_PASS:
            moves = move_generator.gen_moves()
        elif rival_move_type == md.TYPE_1_SINGLE:
            moves = ms.filter_type_1_single(move_generator.gen_type_1_single(), rival_move)
        elif rival_move_type == md.TYPE_2_PAIR:
            moves = ms.filter_type_2_pair(move_generator.gen_type_2_pair(), rival_move)
        elif rival_move_type == md.TYPE_3_TRIPLE:
            moves = ms.filter_type_3_triple(move_generator.gen_type_3_triple(), rival_move)
        elif rival_move_type == md.TYPE_4_BOMB:
            moves = ms.filter_type_4_bomb(
                move_generator.gen_type_4_bomb() + move_generator.gen_type_5_king_bomb(),
                rival_move,
            )
        elif rival_move_type == md.TYPE_5_KING_BOMB:
            moves = []
        elif rival_move_type == md.TYPE_6_3_1:
            moves = ms.filter_type_6_3_1(move_generator.gen_type_6_3_1(), rival_move)
        elif rival_move_type == md.TYPE_7_3_2:
            moves = ms.filter_type_7_3_2(move_generator.gen_type_7_3_2(), rival_move)
        elif rival_move_type == md.TYPE_8_SERIAL_SINGLE:
            moves = ms.filter_type_8_serial_single(
                move_generator.gen_type_8_serial_single(repeat_num=rival_move_len),
                rival_move,
            )
        elif rival_move_type == md.TYPE_9_SERIAL_PAIR:
            moves = ms.filter_type_9_serial_pair(
                move_generator.gen_type_9_serial_pair(repeat_num=rival_move_len),
                rival_move,
            )
        elif rival_move_type == md.TYPE_10_SERIAL_TRIPLE:
            moves = ms.filter_type_10_serial_triple(
                move_generator.gen_type_10_serial_triple(repeat_num=rival_move_len),
                rival_move,
            )
        elif rival_move_type == md.TYPE_11_SERIAL_3_1:
            moves = ms.filter_type_11_serial_3_1(
                move_generator.gen_type_11_serial_3_1(repeat_num=rival_move_len),
                rival_move,
            )
        elif rival_move_type == md.TYPE_12_SERIAL_3_2:
            moves = ms.filter_type_12_serial_3_2(
                move_generator.gen_type_12_serial_3_2(repeat_num=rival_move_len),
                rival_move,
            )
        elif rival_move_type == md.TYPE_13_4_2:
            moves = ms.filter_type_13_4_2(move_generator.gen_type_13_4_2(), rival_move)
        elif rival_move_type == md.TYPE_14_4_22:
            moves = ms.filter_type_14_4_22(move_generator.gen_type_14_4_22(), rival_move)
        else:
            moves = move_generator.gen_moves()

        if rival_move_type not in [md.TYPE_0_PASS, md.TYPE_4_BOMB, md.TYPE_5_KING_BOMB]:
            moves = moves + move_generator.gen_type_4_bomb() + move_generator.gen_type_5_king_bomb()

        if rival_move:
            moves = moves + [[]]

        normalized = []
        for move in moves:
            normalized.append(sorted(move))
        return normalized

    def _match_card_ids(
        self,
        cards: Sequence[landlords_pb2.Card],
        move: Sequence[int],
    ) -> list[str]:
        buckets: dict[int, list[str]] = defaultdict(list)
        for card in cards:
            buckets[self._card_to_env_value(card)].append(card.id)

        selected: list[str] = []
        for value in move:
            if not buckets[value]:
                raise ValueError(f"Cannot match model move {list(move)} to current hand")
            selected.append(buckets[value].pop(0))
        return selected

    def _cards_to_env_values(
        self, cards: Iterable[landlords_pb2.Card]
    ) -> list[int]:
        return [self._card_to_env_value(card) for card in cards]

    def _card_to_env_value(self, card: landlords_pb2.Card) -> int:
        return RANK_TO_ENV_VALUE[card.rank]

    def _is_system_action(self, action: landlords_pb2.TableAction) -> bool:
        label = action.pattern
        return (
            label == "managed_on"
            or label == "managed_off"
            or label == "bid_pass"
            or label.startswith("bid_")
        )

    def _current_lead_move(self, action_seq: Sequence[Sequence[int]]) -> list[int]:
        trailing_passes = 0
        for move in reversed(action_seq):
            if len(move) == 0:
                trailing_passes += 1
                continue
            if trailing_passes >= 2:
                return []
            return list(move)
        return []

    def _last_two_moves(self, action_seq: Sequence[Sequence[int]]) -> list[list[int]]:
        recent = [list(move) for move in action_seq[-2:]]
        while len(recent) < 2:
            recent.insert(0, [])
        return recent


def _load_model_dict() -> dict[str, type[torch.nn.Module]]:
    models_path = DOUZERO_ROOT / "douzero" / "dmc" / "models.py"
    spec = importlib.util.spec_from_file_location("douzero_standalone_models", models_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load DouZero models from {models_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.model_dict


MODEL_DICT = _load_model_dict()


class _LoadedAgent:
    def __init__(
        self,
        position: str,
        model_path: str,
        device: str,
        logger,
    ) -> None:
        self._position = position
        self._device = torch.device(device)
        self._logger = logger
        started = time.perf_counter()
        self._model = self._load_model(position, model_path)
        self._logger.info(
            "loaded role=%s model=%s device=%s elapsed_ms=%.1f",
            position,
            model_path,
            self._device,
            (time.perf_counter() - started) * 1000.0,
        )

    def act(self, infoset: InfoSet) -> list[int]:
        if len(infoset.legal_actions) == 1:
            return infoset.legal_actions[0]

        obs = get_obs(infoset)
        with torch.inference_mode():
            z_batch = torch.from_numpy(obs["z_batch"]).float().to(self._device)
            x_batch = torch.from_numpy(obs["x_batch"]).float().to(self._device)
            predictions = self._model.forward(z_batch, x_batch, return_value=True)["values"]
            values = predictions.detach().cpu().numpy()
        best_action_index = int(np.argmax(values, axis=0)[0])
        return infoset.legal_actions[best_action_index]

    def warmup(self) -> None:
        x_width = ROLE_X_WIDTH[self._position]
        z_batch = torch.zeros((1, 5, 162), dtype=torch.float32, device=self._device)
        x_batch = torch.zeros((1, x_width), dtype=torch.float32, device=self._device)
        with torch.inference_mode():
            _ = self._model.forward(z_batch, x_batch, return_value=True)["values"]
        self._logger.debug("warmed role=%s", self._position)

    def _load_model(self, position: str, model_path: str) -> torch.nn.Module:
        model = MODEL_DICT[position]()
        state_dict = model.state_dict()
        map_location = self._device
        pretrained = torch.load(model_path, map_location=map_location)
        pretrained = {key: value for key, value in pretrained.items() if key in state_dict}
        state_dict.update(pretrained)
        model.load_state_dict(state_dict)
        model.to(self._device)
        model.eval()
        return model
