# Tool 目录

`tool/` 目录保留的是部署验证和 Web 发布辅助工具。

## 当前保留内容

- `web_public_server.dart`：Web 静态资源服务和 `/ws` 代理
- `invite_smoke.dart`：邀请流程 smoke 测试
- `friend_request_smoke.dart`：好友流程 smoke 测试

## 对外入口

- [`run_frontend_windows.ps1`](../run_frontend_windows.ps1) 会调用 `web_public_server.dart`
- 测试代码会直接复用 `invite_smoke.dart`
