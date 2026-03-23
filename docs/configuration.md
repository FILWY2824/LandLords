# 配置总览

项目中所有会随着部署环境变化的参数，都统一写入仓库根目录的 [`landlords.env`](../landlords.env)。

## 谁会读取 `landlords.env`

- [`run_backend_windows.ps1`](../run_backend_windows.ps1)：Windows 后端配置、编译、运行
- [`run_frontend_windows.ps1`](../run_frontend_windows.ps1)：Windows 前端 Web 构建、发布、代理
- [`backend/ai_service/douzero_onnx/export_onnx.py`](../backend/ai_service/douzero_onnx/export_onnx.py)：ONNX 导出，默认也会读取同一份配置

## 配置原则

- 仓库内部路径优先写相对路径，例如 `backend/ai_models/onnx/sl`
- 机器本地 SDK 优先写绝对路径，例如 `D:/sdk/protobuf`
- 用户只修改已有值，不需要自己新增配置键

## 一、后端构建与原生依赖

这组键决定 CMake 如何找到原生依赖：

- `LANDLORDS_CMAKE_GENERATOR`
- `LANDLORDS_CMAKE_PLATFORM`
- `LANDLORDS_CMAKE_BUILD_DIR`
- `LANDLORDS_CMAKE_BUILD_CONFIG`
- `LANDLORDS_CMAKE_BUILD_TYPE`
- `LANDLORDS_SERVER_EXE`
- `LANDLORDS_USE_LOCAL_WINDOWS_DEPS`
- `LANDLORDS_WINDOWS_DEPS_ROOT`
- `LANDLORDS_PROTOBUF_ROOT`
- `LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE`
- `LANDLORDS_PROTOBUF_INCLUDE_DIR`
- `LANDLORDS_PROTOBUF_LIBRARY`
- `LANDLORDS_LIBEVENT_ROOT`
- `LANDLORDS_LIBEVENT_CMAKE_DIR`
- `LANDLORDS_CMAKE_PREFIX_PATH`
- `LANDLORDS_ENABLE_ONNXRUNTIME`
- `LANDLORDS_ONNXRUNTIME_ROOT`

### 推荐的 Windows bundle 模式

如果你的依赖目录结构类似下面这样，建议优先用 bundle 模式，只改一个根路径即可：

```text
<deps_root>/protobuf/bin/protoc.exe
<deps_root>/protobuf/include
<deps_root>/protobuf/lib/libprotobuf.lib
<deps_root>/libevent/lib/cmake/libevent
```

对应配置：

```env
LANDLORDS_USE_LOCAL_WINDOWS_DEPS=ON
LANDLORDS_WINDOWS_DEPS_ROOT=D:/sdk/landlords/windows_deps
```

### 分开指定依赖

当 protobuf 和 libevent 不在同一目录时，再改成手动模式：

```env
LANDLORDS_USE_LOCAL_WINDOWS_DEPS=OFF
LANDLORDS_PROTOBUF_ROOT=D:/sdk/protobuf
LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE=D:/sdk/protobuf/bin/protoc.exe
LANDLORDS_PROTOBUF_INCLUDE_DIR=D:/sdk/protobuf/include
LANDLORDS_PROTOBUF_LIBRARY=D:/sdk/protobuf/lib/libprotobuf.lib
LANDLORDS_LIBEVENT_ROOT=D:/sdk/libevent
LANDLORDS_LIBEVENT_CMAKE_DIR=D:/sdk/libevent/lib/cmake/libevent
LANDLORDS_ONNXRUNTIME_ROOT=D:/sdk/onnxruntime/Microsoft.ML.OnnxRuntime.1.24.3
```

## 二、前端编译期配置

这组键会被前端脚本转成 `--dart-define`：

- `LANDLORDS_WS_URL`
- `LANDLORDS_GITHUB_REPO`
- `LANDLORDS_DOWNLOAD_URL`

推荐规则：

- Web 同域部署时，`LANDLORDS_WS_URL` 留空
- Web 反向代理转发到后端时，交给 `LANDLORDS_BACKEND_WS_PROXY`
- 登录页或发布页需要展示仓库链接时，设置 `LANDLORDS_GITHUB_REPO`
- 如果你有自己的安装包或发布页链接，再填写 `LANDLORDS_DOWNLOAD_URL`

## 三、后端运行期配置

这组键控制服务监听方式和落盘目录：

- `LANDLORDS_HOST`
- `LANDLORDS_PORT`
- `LANDLORDS_WS_PORT`
- `LANDLORDS_DATA_DIR`
- `LANDLORDS_LOG_LEVEL`
- `LANDLORDS_ROOM_TICK_INTERVAL_MS`

常用示例：

```env
LANDLORDS_HOST=0.0.0.0
LANDLORDS_PORT=23001
LANDLORDS_WS_PORT=23002
LANDLORDS_DATA_DIR=runtime
LANDLORDS_LOG_LEVEL=INFO
```

说明：

- `127.0.0.1` 只允许本机访问
- `0.0.0.0` 适合局域网、公网或反向代理转发

## 四、Web 发布服务

这组键由 [`run_frontend_windows.ps1`](../run_frontend_windows.ps1) 使用：

- `LANDLORDS_WEB_HOST`
- `LANDLORDS_WEB_PORT`
- `LANDLORDS_BACKEND_WS_PROXY`

示例：

```env
LANDLORDS_WEB_HOST=0.0.0.0
LANDLORDS_WEB_PORT=23000
LANDLORDS_BACKEND_WS_PROXY=ws://127.0.0.1:23002/ws
```

## 五、ONNX 模型

这组键决定 C++ 后端使用哪套 ONNX 模型：

- `LANDLORDS_DOUZERO_ONNX_DIR`
- `LANDLORDS_DOUZERO_ONNX_DIR_EASY`
- `LANDLORDS_DOUZERO_ONNX_DIR_NORMAL`
- `LANDLORDS_DOUZERO_ONNX_DIR_HARD`
- `LANDLORDS_ONNX_NUM_THREADS`
- `LANDLORDS_HINT_BOT_DIFFICULTY`
- `LANDLORDS_MANAGED_BOT_DIFFICULTY`

默认模型目录已经在仓库中准备好：

- `backend/ai_models/onnx/douzero_ADP`
- `backend/ai_models/onnx/sl`
- `backend/ai_models/onnx/douzero_WP`

## 六、ONNX 导出与 Python 工具

这组键主要给 ONNX 导出脚本使用：

- `LANDLORDS_PYTHON`
- `LANDLORDS_DOUZERO_ROOT`
- `LANDLORDS_DOUZERO_BASELINE_DIR`
- `LANDLORDS_DOUZERO_DEVICE`
- `LANDLORDS_DOUZERO_NUM_THREADS`
- `LANDLORDS_DOUZERO_PRELOAD`
- `LANDLORDS_DOUZERO_WARMUP`
- `LANDLORDS_DOUZERO_EXPORT_OUTPUT_DIR`
- `LANDLORDS_DOUZERO_EXPORT_DEVICE`
- `LANDLORDS_DOUZERO_LOG_LEVEL`

详细流程见 [onnx_deployment.md](onnx_deployment.md)。

## 七、测试配置

这组键让测试脚本不依赖硬编码地址：

- `LANDLORDS_TEST_HOST`
- `LANDLORDS_TEST_TCP_PORT`
- `LANDLORDS_TEST_WS_PORT`

## 修改配置后的注意事项

- 改了 CMake 或依赖路径后，重新执行 [`run_backend_windows.ps1`](../run_backend_windows.ps1)
- 改了前端地址或 `--dart-define` 相关键后，重新执行 [`run_frontend_windows.ps1`](../run_frontend_windows.ps1)
- 改了端口后，同时检查前端代理、测试脚本和对外访问地址是否一致
