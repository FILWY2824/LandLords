# AI Models

`backend/ai_models/` 存放默认可直接部署的 ONNX 模型目录。

## 默认目录

- `onnx/douzero_ADP`
- `onnx/sl`
- `onnx/douzero_WP`

每个目录通常包含：

- `landlord.onnx`
- `landlord_up.onnx`
- `landlord_down.onnx`
- `manifest.json`

## 与配置的关系

这些目录默认由以下配置引用：

- `LANDLORDS_DOUZERO_ONNX_DIR_EASY`
- `LANDLORDS_DOUZERO_ONNX_DIR_NORMAL`
- `LANDLORDS_DOUZERO_ONNX_DIR_HARD`

## 重新导出

```powershell
python .\backend\ai_service\douzero_onnx\export_onnx.py --overwrite
```

详细见 [docs/onnx_deployment.md](../../docs/onnx_deployment.md)。
