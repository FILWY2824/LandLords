from __future__ import annotations

import argparse
import json
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from adapter import DouZeroAdapter
from generated import landlords_pb2
from logging_utils import get_logger

LOGGER = get_logger("douzero_proxy.server")


class LandlordsThreadingHTTPServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


class DouZeroRequestHandler(BaseHTTPRequestHandler):
    adapter: DouZeroAdapter

    def do_GET(self) -> None:  # noqa: N802
        if self.path != "/healthz":
            self._write_text(HTTPStatus.NOT_FOUND, "not found")
            return

        body = {
            "status": "ok",
            "baseline_dir": str(self.adapter.baseline_dir),
            "device": self.adapter.device,
            "loaded_positions": self.adapter.loaded_positions,
        }
        self._write_json(HTTPStatus.OK, body)

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/choose_move":
            self._write_text(HTTPStatus.NOT_FOUND, "not found")
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(content_length)
        snapshot = landlords_pb2.RoomSnapshot()
        try:
            snapshot.ParseFromString(body)
            started = time.perf_counter()
            response = self.adapter.choose_move(snapshot)
            payload = response.SerializeToString()
            elapsed_ms = (time.perf_counter() - started) * 1000.0
            LOGGER.debug(
                "choose_move room=%s turn=%s self_cards=%d decision_cards=%d elapsed_ms=%.1f",
                snapshot.room_id,
                snapshot.current_turn_player_id,
                len(snapshot.self_cards),
                len(response.card_ids),
                elapsed_ms,
            )

            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", "application/x-protobuf")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionAbortedError, ConnectionResetError) as exc:
            LOGGER.warning(
                "client disconnected during response room=%s turn=%s error=%s",
                snapshot.room_id,
                snapshot.current_turn_player_id,
                exc,
            )
        except Exception:
            LOGGER.exception(
                "choose_move failed room=%s turn=%s",
                snapshot.room_id,
                snapshot.current_turn_player_id,
            )
            self._write_text(HTTPStatus.INTERNAL_SERVER_ERROR, "choose_move failed")

    def log_message(self, format: str, *args: object) -> None:
        LOGGER.debug("%s - %s", self.address_string(), format % args)

    def _write_text(self, status: HTTPStatus, body: str) -> None:
        payload = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _write_json(self, status: HTTPStatus, body: dict[str, object]) -> None:
        payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def main() -> None:
    parser = argparse.ArgumentParser(description="Local DouZero inference proxy")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=31001)
    parser.add_argument("--baseline-dir", type=Path, default=None)
    args = parser.parse_args()

    adapter = DouZeroAdapter(args.baseline_dir)
    DouZeroRequestHandler.adapter = adapter
    server = LandlordsThreadingHTTPServer((args.host, args.port), DouZeroRequestHandler)
    LOGGER.info(
        "listening on http://%s:%d using %s device=%s",
        args.host,
        args.port,
        adapter.baseline_dir,
        adapter.device,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
