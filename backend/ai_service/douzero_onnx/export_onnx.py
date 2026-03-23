from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import torch
from torch import nn

from adapter import MODEL_DICT, ROLE_FILES, ROLE_X_WIDTH, ROOT_DIR
from logging_utils import get_logger

LOGGER = get_logger("douzero_onnx.export_onnx")


def load_landlords_env() -> None:
    env_path = ROOT_DIR / "landlords.env"
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        name, value = line.split("=", 1)
        name = name.strip()
        value = value.strip()
        if not name:
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        os.environ[name] = value


class ValueHeadWrapper(nn.Module):
    def __init__(self, model: nn.Module) -> None:
        super().__init__()
        self.model = model

    def forward(self, z: torch.Tensor, x: torch.Tensor) -> torch.Tensor:
        return self.model(z, x, return_value=True)["values"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export DouZero checkpoints to ONNX")
    parser.add_argument(
        "--baseline-dir",
        type=Path,
        default=Path(
            os.environ.get(
                "LANDLORDS_DOUZERO_BASELINE_DIR",
                ROOT_DIR / "third_party" / "baselines" / "douzero_ADP",
            )
        ),
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(
            os.environ.get(
                "LANDLORDS_DOUZERO_EXPORT_OUTPUT_DIR",
                ROOT_DIR / "backend" / "ai_models" / "onnx" / "douzero_ADP",
            )
        ),
    )
    parser.add_argument(
        "--device",
        default=os.environ.get("LANDLORDS_DOUZERO_EXPORT_DEVICE", "cpu"),
    )
    parser.add_argument("--opset", type=int, default=14)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args()


def require_onnx() -> None:
    try:
        import onnx  # noqa: F401
    except ImportError as exc:
        raise SystemExit(
            "ONNX export requires the Python package 'onnx'. "
            "Install it in your model environment first."
        ) from exc


def load_model(role: str, checkpoint_path: Path, device: torch.device) -> nn.Module:
    model = MODEL_DICT[role]()
    state_dict = model.state_dict()
    pretrained = torch.load(checkpoint_path, map_location=device)
    pretrained = {key: value for key, value in pretrained.items() if key in state_dict}
    state_dict.update(pretrained)
    model.load_state_dict(state_dict)
    model.to(device)
    model.eval()
    return ValueHeadWrapper(model)


def export_role(
    role: str,
    checkpoint_path: Path,
    output_path: Path,
    device: torch.device,
    opset: int,
) -> None:
    x_width = ROLE_X_WIDTH[role]
    model = load_model(role, checkpoint_path, device)
    z_dummy = torch.zeros((1, 5, 162), dtype=torch.float32, device=device)
    x_dummy = torch.zeros((1, x_width), dtype=torch.float32, device=device)

    LOGGER.info("exporting role=%s checkpoint=%s -> %s", role, checkpoint_path, output_path)
    with torch.inference_mode():
        torch.onnx.export(
            model,
            (z_dummy, x_dummy),
            str(output_path),
            export_params=True,
            opset_version=opset,
            input_names=["z_batch", "x_batch"],
            output_names=["values"],
            dynamic_axes={
                "z_batch": {0: "num_legal_actions"},
                "x_batch": {0: "num_legal_actions"},
                "values": {0: "num_legal_actions"},
            },
        )


def main() -> None:
    load_landlords_env()
    args = parse_args()
    require_onnx()

    baseline_dir = args.baseline_dir.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    device = torch.device(args.device)

    def to_portable_path(path: Path) -> str:
        try:
            return path.resolve().relative_to(ROOT_DIR.resolve()).as_posix()
        except ValueError:
            return str(path.resolve())

    manifest: dict[str, object] = {
        "baseline_dir": to_portable_path(baseline_dir),
        "device": str(device),
        "opset": args.opset,
        "roles": {},
    }

    for role, filename in ROLE_FILES.items():
        checkpoint_path = baseline_dir / filename
        if not checkpoint_path.exists():
            raise SystemExit(f"Missing checkpoint: {checkpoint_path}")

        output_path = output_dir / filename.replace(".ckpt", ".onnx")
        if output_path.exists() and not args.overwrite:
            LOGGER.info("skipping existing file role=%s path=%s", role, output_path)
        else:
            export_role(role, checkpoint_path, output_path, device, args.opset)
        manifest["roles"][role] = {
            "checkpoint": to_portable_path(checkpoint_path),
            "onnx": to_portable_path(output_path),
            "x_width": ROLE_X_WIDTH[role],
            "z_shape": [1, 5, 162],
        }

    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    LOGGER.info("manifest written to %s", manifest_path)


if __name__ == "__main__":
    main()
