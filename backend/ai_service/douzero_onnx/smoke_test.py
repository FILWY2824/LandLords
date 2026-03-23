from __future__ import annotations

from adapter import DouZeroAdapter
from generated import landlords_pb2


def make_card(card_id: str, rank: str, suit: str) -> landlords_pb2.Card:
    card = landlords_pb2.Card()
    card.id = card_id
    card.rank = rank
    card.suit = suit
    return card


def build_snapshot() -> landlords_pb2.RoomSnapshot:
    snapshot = landlords_pb2.RoomSnapshot()
    snapshot.room_id = "smoke_room"
    snapshot.phase = landlords_pb2.ROOM_PHASE_PLAYING
    snapshot.mode = landlords_pb2.MATCH_MODE_VS_BOT
    snapshot.current_turn_player_id = "bot_landlord"

    landlord = snapshot.players.add()
    landlord.player_id = "bot_landlord"
    landlord.display_name = "Bot Landlord"
    landlord.is_bot = True
    landlord.role = landlords_pb2.PLAYER_ROLE_LANDLORD
    landlord.cards_left = 20

    down = snapshot.players.add()
    down.player_id = "human_down"
    down.display_name = "Human Down"
    down.is_bot = False
    down.role = landlords_pb2.PLAYER_ROLE_FARMER
    down.cards_left = 17

    up = snapshot.players.add()
    up.player_id = "bot_up"
    up.display_name = "Bot Up"
    up.is_bot = True
    up.role = landlords_pb2.PLAYER_ROLE_FARMER
    up.cards_left = 17

    hand = [
        ("c1", "3", "S"),
        ("c2", "3", "H"),
        ("c3", "4", "S"),
        ("c4", "4", "H"),
        ("c5", "5", "S"),
        ("c6", "5", "H"),
        ("c7", "6", "S"),
        ("c8", "6", "H"),
        ("c9", "7", "S"),
        ("c10", "7", "H"),
        ("c11", "8", "S"),
        ("c12", "8", "H"),
        ("c13", "9", "S"),
        ("c14", "9", "H"),
        ("c15", "10", "S"),
        ("c16", "J", "S"),
        ("c17", "Q", "S"),
        ("c18", "K", "S"),
        ("c19", "A", "S"),
        ("c20", "2", "S"),
    ]
    for card_id, rank, suit in hand:
        snapshot.self_cards.append(make_card(card_id, rank, suit))

    for card_id, rank, suit in [("l1", "Q", "H"), ("l2", "K", "H"), ("l3", "A", "H")]:
        snapshot.landlord_cards.append(make_card(card_id, rank, suit))

    return snapshot


def main() -> None:
    adapter = DouZeroAdapter()
    snapshot = build_snapshot()
    response = adapter.choose_move(snapshot)
    if not response.card_ids:
        raise SystemExit("DouZero smoke test failed: no move returned")
    print("move", list(response.card_ids))


if __name__ == "__main__":
    main()
