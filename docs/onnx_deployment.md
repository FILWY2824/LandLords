# ONNX 部署与导出

这份文档专门回答三件事：

1. 仓库自带的 ONNX 模型怎么直接部署
2. 如果用户要自己从 checkpoint 重新导出 ONNX，该怎么做
3. Windows 导出的 ONNX 文件能不能拿到 Linux 用

## 1. 直接使用仓库自带 ONNX

默认模型目录已经放在仓库里：

- `backend/ai_models/onnx/douzero_ADP`
- `backend/ai_models/onnx/sl`
- `backend/ai_models/onnx/douzero_WP`

对应配置键：

- `LANDLORDS_DOUZERO_ONNX_DIR_EASY`
- `LANDLORDS_DOUZERO_ONNX_DIR_NORMAL`
- `LANDLORDS_DOUZERO_ONNX_DIR_HARD`

只要这些目录里有下面这些文件，C++ 后端就可以直接加载：

- `landlord.onnx`
- `landlord_up.onnx`
- `landlord_down.onnx`
- `manifest.json`

然后直接执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1
```

## 2. 自己重新导出 ONNX

### 前提条件

- Python `3.9+`
- 可用的 DouZero checkpoint
- `torch`
- `onnx`
- `landlords.env` 中的以下键已经按你的环境改好：

```env
LANDLORDS_PYTHON=python
LANDLORDS_DOUZERO_ROOT=third_party/DouZero
LANDLORDS_DOUZERO_BASELINE_DIR=third_party/baselines/douzero_ADP
LANDLORDS_DOUZERO_EXPORT_OUTPUT_DIR=backend/ai_models/onnx/douzero_ADP
LANDLORDS_DOUZERO_EXPORT_DEVICE=cpu
```

### 导出命令

导出脚本现在会自动读取仓库根目录的 `landlords.env`，所以不需要再套一层 PowerShell 包装脚本。

使用默认配置导出：

```powershell
python .\backend\ai_service\douzero_onnx\export_onnx.py --overwrite
```

指定 baseline 和输出目录导出：

```powershell
python .\backend\ai_service\douzero_onnx\export_onnx.py `
  --baseline-dir .\third_party\baselines\douzero_ADP `
  --output-dir .\backend\ai_models\onnx\douzero_ADP `
  --device cpu `
  --overwrite
```

### 导出结果

输出目录通常包含：

- `landlord.onnx`
- `landlord_up.onnx`
- `landlord_down.onnx`
- `manifest.json`

`manifest.json` 现在会尽量写仓库相对路径，方便跨机器和跨平台复用。

## 3. Windows 导出的 ONNX 能不能在 Linux 上用

可以，但要区分“模型文件”和“运行时库”。

- `*.onnx` 文件本身是跨平台的，可以从 Windows 直接复制到 Linux
- `manifest.json` 只要使用相对路径或 Linux 上也存在对应路径，也可以继续用
- 不能直接跨平台复用的是 Windows 的 ONNX Runtime SDK、`.lib`、`.dll` 和 Windows 编译出的后端二进制

也就是说：

1. 你可以在 Windows 上导出 ONNX
2. 再把 `backend/ai_models/onnx/<你的模型目录>` 整个拷到 Linux
3. Linux 侧重新准备 Linux 版 ONNX Runtime
4. Linux 侧重新编译 `landlords_server`

## 4. Linux 上如何使用自己导出的 ONNX

先把导出的模型目录拷到 Linux，例如：

```text
backend/ai_models/onnx/custom_wp
```

然后修改 `landlords.env` 或 Linux 环境变量：

```env
LANDLORDS_DOUZERO_ONNX_DIR_HARD=backend/ai_models/onnx/custom_wp
LANDLORDS_ONNXRUNTIME_ROOT=/opt/onnxruntime/Microsoft.ML.OnnxRuntime.1.24.3
```

最后按 Linux 的 CMake 命令重新编译后端即可。

## 5. 如果用户要完全自己配一套 ONNX

推荐按这个顺序：

1. 准备自己的 checkpoint
2. 用 `export_onnx.py` 导出到新的模型目录
3. 检查导出的三个 `onnx` 文件和 `manifest.json`
4. 修改 `landlords.env` 中的 `LANDLORDS_DOUZERO_ONNX_DIR_*`
5. 重新运行后端脚本或 Linux 构建命令

## 6. 常见问题

### 导出时报 `onnx` 模块不存在

在当前 Python 环境里安装 `onnx`，然后重新执行导出。

### 导出时报 checkpoint 缺失

确认 `LANDLORDS_DOUZERO_BASELINE_DIR` 或 `--baseline-dir` 指向的目录中存在对应 `ckpt` 文件。

### 后端启动时报模型缺失

确认 `LANDLORDS_DOUZERO_ONNX_DIR_EASY`、`LANDLORDS_DOUZERO_ONNX_DIR_NORMAL`、`LANDLORDS_DOUZERO_ONNX_DIR_HARD` 指向的目录中都有 `landlord.onnx`。
