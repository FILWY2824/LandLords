# AI Runtime

This project now supports in-process DouZero ONNX inference in the C++ server.
The play logic no longer needs the Python proxy when you run the ONNX path.

## Current Recommended Runtime

Use the C++ backend with ONNX:

```bat
F:\CodeXProject\LandLords\run_backend_with_onnx.cmd
```

The script sets:

```text
LANDLORDS_BOT_BACKEND=onnx
LANDLORDS_DOUZERO_ONNX_DIR=F:\CodeXProject\LandLords\backend\ai_models\onnx\douzero_ADP
LANDLORDS_LOG_LEVEL=INFO
```

Artificial bot delay is disabled by default in the ONNX path:

```text
LANDLORDS_BOT_BID_DELAY_MIN_MS=0
LANDLORDS_BOT_BID_DELAY_MAX_MS=0
LANDLORDS_BOT_PLAY_DELAY_MIN_MS=0
LANDLORDS_BOT_PLAY_DELAY_MAX_MS=0
LANDLORDS_MANAGED_DELAY_MIN_MS=0
LANDLORDS_MANAGED_DELAY_MAX_MS=0
LANDLORDS_ROOM_TICK_INTERVAL_MS=100
```

You can raise logging detail while debugging:

```bat
set LANDLORDS_LOG_LEVEL=DEBUG
F:\CodeXProject\LandLords\run_backend_with_onnx.cmd
```

Log levels:

```text
DEBUG
INFO
WARN
ERROR
```

## Rebuild The Backend With ONNX

```bat
cd /d F:\CodeXProject\LandLords
cmake -G "Visual Studio 17 2022" -A x64 ^
  -S backend\server ^
  -B backend\server\build-vs ^
  -DLANDLORDS_ENABLE_ONNXRUNTIME=ON ^
  -DLANDLORDS_ONNXRUNTIME_ROOT=F:/CodeXProject/LandLords/third_party/onnxruntime/Microsoft.ML.OnnxRuntime.1.24.3
cmake --build backend\server\build-vs --config Debug --target landlords_server landlords_room_tests landlords_onnx_tests
```

## Export DouZero Checkpoints To ONNX

If you replace the baseline checkpoints, export them again:

```bat
F:\CodeXProject\LandLords\backend\ai_service\douzero_proxy\export_onnx.cmd douzero_ADP
```

Output directory:

```text
F:\CodeXProject\LandLords\backend\ai_models\onnx\douzero_ADP
```

## Verification

The current validation flow is:

```bat
F:\CodeXProject\LandLords\backend\server\build-vs\Debug\landlords_onnx_tests.exe
F:\CodeXProject\LandLords\backend\server\build-vs\Debug\landlords_room_tests.exe
```

`landlords_onnx_tests.exe` checks:

- ONNX Runtime can load all three DouZero role models
- a smoke snapshot can produce a valid move
- multiple full ONNX-vs-ONNX bot rounds can finish normally
- round scoring remains valid at game end

`landlords_room_tests.exe` checks:

- ordinary room simulations still finish
- bidding logic stays valid
- manual-play simulation remains legal
- 25 second trustee takeover still works
