# Vendored DouZero Subset

This repository keeps only the minimal DouZero source subset required for ONNX export and verification.

Retained content:

- `douzero/dmc/models.py`
- `douzero/env/*`
- package `__init__.py` files
- [`LICENSE`](LICENSE)

Removed from this vendored copy:

- training code
- evaluation code
- CI files
- package publishing files
- images and extra upstream docs

Upstream project:

- [kwai/DouZero](https://github.com/kwai/DouZero)

Why this subset exists here:

- [`backend/ai_service/douzero_onnx/export_onnx.py`](../../backend/ai_service/douzero_onnx/export_onnx.py) imports DouZero model and environment code
- the runtime game server does not execute Python agents
- the Python directory is kept only for model export and consistency checks
