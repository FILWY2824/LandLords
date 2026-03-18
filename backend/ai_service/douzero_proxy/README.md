# DouZero Proxy

This service loads the official DouZero weights from `third_party/baselines`
and exposes a local HTTP + protobuf endpoint for the C++ backend.

Default endpoint:

```text
http://127.0.0.1:31001/choose_move
```

Default model set:

```text
third_party/baselines/douzero_ADP
```

Run with:

```powershell
F:\CodeXProject\LandLords\backend\ai_service\douzero_proxy\run_proxy.ps1
```

Or on Windows `cmd`:

```bat
F:\CodeXProject\LandLords\backend\ai_service\douzero_proxy\run_proxy.cmd
```

Choose another baseline:

```bat
F:\CodeXProject\LandLords\backend\ai_service\douzero_proxy\run_proxy.cmd douzero_WP
F:\CodeXProject\LandLords\backend\ai_service\douzero_proxy\run_proxy.cmd sl
```

Log level:

```bat
set LANDLORDS_PROXY_LOG_LEVEL=DEBUG
```

Export ONNX:

```bat
F:\CodeXProject\LandLords\backend\ai_service\douzero_proxy\export_onnx.cmd douzero_ADP
```
