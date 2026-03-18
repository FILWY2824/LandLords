from __future__ import annotations

import logging
import os
import sys
from threading import Lock

_CONFIG_LOCK = Lock()
_CONFIGURED = False


def _parse_level() -> int:
    raw = os.environ.get("LANDLORDS_PROXY_LOG_LEVEL", "INFO").strip().upper()
    return {
        "DEBUG": logging.DEBUG,
        "INFO": logging.INFO,
        "WARN": logging.WARNING,
        "WARNING": logging.WARNING,
        "ERROR": logging.ERROR,
    }.get(raw, logging.INFO)


def configure_logging() -> None:
    global _CONFIGURED
    if _CONFIGURED:
        return

    with _CONFIG_LOCK:
        if _CONFIGURED:
            return

        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(
            logging.Formatter(
                fmt="[%(asctime)s][%(levelname)s][%(name)s] %(message)s",
                datefmt="%H:%M:%S",
            )
        )

        logger = logging.getLogger("landlords")
        logger.handlers.clear()
        logger.addHandler(handler)
        logger.setLevel(_parse_level())
        logger.propagate = False
        _CONFIGURED = True


def get_logger(name: str) -> logging.Logger:
    configure_logging()
    return logging.getLogger(f"landlords.{name}")
