# Web Public Access

This project can now be published through a single local port:

- `23000` serves the Flutter Web files
- `23000/ws` proxies browser WebSocket traffic to the local backend on `23002`

This means Cloudflare only needs to expose local port `23000`.

## 1. Start the backend

Open a WindTerm tab and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_with_onnx.ps1
```

The backend will listen on:

- `0.0.0.0:23001` for native TCP clients
- `0.0.0.0:23002/ws` for the local WebSocket bridge

## 2. Start the public web service

Open another WindTerm tab and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_frontend_web_23000.ps1
```

This script will:

1. build Flutter Web in release mode
2. start a local public server on `0.0.0.0:23000`
3. proxy `/ws` to `ws://127.0.0.1:23002/ws`

## 3. Point Cloudflare at local port 23000

Expose your domain to:

- local address: `http://127.0.0.1:23000`

Because the page and WebSocket are both served through the same origin,
remote players can open the domain and play without any extra client setup.

## Optional environment variables

Before running `run_frontend_web_23000.ps1`, you can override:

```powershell
$env:LANDLORDS_WEB_HOST = "0.0.0.0"
$env:LANDLORDS_WEB_PORT = "23000"
$env:LANDLORDS_BACKEND_WS_PROXY = "ws://127.0.0.1:23002/ws"
```

## Notes

- No Chrome window is opened.
- Logs stay in the WindTerm terminal tab.
- If you change Flutter code, rerun the frontend script to rebuild the web bundle.
