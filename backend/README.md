# Backend 模块

`backend/` 目录包含 C++ 服务端、Python 侧模型工具和默认 ONNX 模型。

## 子模块

- [server/README.md](server/README.md)：C++ 联机服务端
- [ai_service/README.md](ai_service/README.md)：Python 侧 ONNX 导出工具
- [ai_models/README.md](ai_models/README.md)：默认 ONNX 模型目录

## 当前部署入口

- [`run_backend_windows.ps1`](../run_backend_windows.ps1)：Windows 后端编译并运行
- [docs/onnx_deployment.md](../docs/onnx_deployment.md)：ONNX 替换与导出
