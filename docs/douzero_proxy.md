# DouZero 模型接入说明

这套接入方案不是把 PyTorch 硬塞进 C++ 进程，而是：

1. Python 服务加载 `third_party/baselines` 下的官方 DouZero 权重
2. C++ 后端通过 HTTP + protobuf 调用本地推理服务
3. 模型服务返回一手合法牌，C++ 后端继续执行原有出牌流程

## 当前默认模型目录

```text
F:\CodeXProject\LandLords\third_party\baselines\douzero_ADP
```

如果你想换成 `douzero_WP` 或 `sl`，运行服务时把 `--baseline-dir` 换掉即可。

## 当前默认推理地址

```text
http://127.0.0.1:31001/choose_move
```

后端读取的环境变量是：

```text
LANDLORDS_BOT_ENDPOINT
LANDLORDS_BOT_TIMEOUT_SECONDS
```

## 单独启动模型服务

```powershell
F:\CodeXProject\LandLords\backend\ai_service\douzero_proxy\run_proxy.ps1
```

## 一起启动模型服务和 C++ 后端

```powershell
F:\CodeXProject\LandLords\run_backend_with_douzero.ps1
```

## 技术实现位置

- 模型适配层：`backend/ai_service/douzero_proxy/adapter.py`
- HTTP 服务：`backend/ai_service/douzero_proxy/server.py`
- 协议生成：`backend/ai_service/douzero_proxy/generated/landlords_pb2.py`
- C++ 远端策略入口：`backend/server/src/bot_strategy.cpp`
