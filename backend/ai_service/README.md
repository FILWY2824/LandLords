# AI Service 模块

`backend/ai_service/` 现在只保留 Python 侧的 ONNX 导出与校验工具。

## 当前定位

- 默认部署方案：C++ 后端直接加载 ONNX
- 不再保留 Python 代理运行链路
- Python 目录只用于导出 ONNX、做一致性校验和模型辅助验证

## 子模块

- [douzero_onnx/README.md](douzero_onnx/README.md)

## 相关文档

- [docs/onnx_deployment.md](../../docs/onnx_deployment.md)
