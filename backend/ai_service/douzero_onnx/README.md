# DouZero ONNX 工具

这个目录只保留 DouZero checkpoint 到 ONNX 的导出与校验工具。

## 当前定位

- 不再提供 Python 代理服务
- 当前实际出牌决策由 C++ 后端直接加载 ONNX 完成
- Python 侧只用于模型导出、校验和必要的辅助验证

## 主要文件

- `adapter.py`：DouZero checkpoint 适配与本地推理辅助
- `export_onnx.py`：checkpoint 导出 ONNX
- `verify_onnx_export.py`：对比 checkpoint 与 ONNX 决策是否一致
- `smoke_test.py`：本地简单验证
- `generated/landlords_pb2.py`：Python protobuf 生成文件

## 导出命令

```powershell
python .\backend\ai_service\douzero_onnx\export_onnx.py --overwrite
```

脚本会自动读取仓库根目录的 `landlords.env`。

详细见 [docs/onnx_deployment.md](../../../docs/onnx_deployment.md)。
