# LandLords

面向 Web 联机部署的斗地主项目。前端使用 Flutter Web，后端使用 `C++20 + libevent + protobuf`，机器人默认采用 `DouZero ONNX`，直接在 C++ 服务端进程内推理，不再依赖 Python 代理服务。

## 项目优势

- 开源部署入口已经收敛成一份正式配置文件 [`landlords.env`](landlords.env) 和两个 Windows 主脚本，用户只需要修改现成配置，不需要自己补模板或重新拼命令。
- 后端依赖路径、监听地址、端口、Web 代理、ONNX 模型目录都统一进入配置文件，适合不同服务器环境直接替换部署。
- 出牌决策链路已经收敛为 ONNX 方案，运行时不再保留 Python 代理进程，部署结构更简单、问题定位更直接。
- 仓库只保留当前维护的内容：Web 前端、C++ 后端、ONNX 导出工具、测试代码和必要文档；旧的 Android / Windows 客户端工程目录和冗余第三方文件已移除。
- 测试源码保留，构建产物、运行日志、调试缓存和临时目录不作为开源内容保留，方便别人复现又不会把仓库带脏。

## 当前推荐入口

```text
landlords.env                  正式配置文件，用户直接修改
run_backend_windows.ps1        Windows 后端配置、编译、运行脚本
run_frontend_windows.ps1       Windows 前端 Web 构建、运行脚本
docs/onnx_deployment.md        ONNX 导出、替换、跨平台使用说明
```

模块文档入口：

- [docs/README.md](docs/README.md)
- [backend/README.md](backend/README.md)
- [backend/server/README.md](backend/server/README.md)
- [backend/ai_service/README.md](backend/ai_service/README.md)
- [backend/ai_service/douzero_onnx/README.md](backend/ai_service/douzero_onnx/README.md)
- [backend/ai_models/README.md](backend/ai_models/README.md)
- [lib/README.md](lib/README.md)
- [shared/README.md](shared/README.md)
- [shared/proto/README.md](shared/proto/README.md)
- [tool/README.md](tool/README.md)
- [test/README.md](test/README.md)

## 已核实的版本信息

下表用于说明本仓库当前推荐的部署版本范围：

| 组件 | 推荐版本 | 说明 |
| --- | --- | --- |
| Flutter SDK | `3.38.9` | 当前整理阶段用于 Web 构建验证 |
| Dart SDK | `3.10.8` | 来自 [`pubspec.yaml`](pubspec.yaml) 的 SDK 约束 |
| CMake | `3.29.2` | 当前后端配置与编译已实际使用 |
| Visual Studio | `Visual Studio 2022` + `MSVC v143` | Windows 后端推荐环境 |
| Protobuf C++ | `3.20.x` 兼容版本 | 当前工程和生成代码按这一代版本兼容 |
| libevent | `2.1.x` | 需要可被 `find_package(Libevent CONFIG REQUIRED)` 发现 |
| ONNX Runtime | `1.24.3` | 当前文档和配置按此版本整理 |
| Python | `3.9+` | ONNX 导出和校验工具推荐版本 |

## 部署前先改什么

直接编辑 [`landlords.env`](landlords.env)。仓库已经把所有正式配置键和默认示例值写进去，用户不需要复制模板，只需要把示例值改成自己机器的实际值。

第一次部署最需要优先确认的是这些键：

- `LANDLORDS_PROTOBUF_ROOT`
- `LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE`
- `LANDLORDS_PROTOBUF_INCLUDE_DIR`
- `LANDLORDS_PROTOBUF_LIBRARY`
- `LANDLORDS_LIBEVENT_ROOT`
- `LANDLORDS_LIBEVENT_CMAKE_DIR`
- `LANDLORDS_ONNXRUNTIME_ROOT`
- `LANDLORDS_HOST`
- `LANDLORDS_PORT`
- `LANDLORDS_WS_PORT`
- `LANDLORDS_WEB_HOST`
- `LANDLORDS_WEB_PORT`
- `LANDLORDS_BACKEND_WS_PROXY`

详细说明见 [docs/configuration.md](docs/configuration.md)。

## Windows 脚本部署

### 1. 启动后端

这个脚本会自动完成三件事：

1. 读取 `landlords.env`
2. 运行 CMake 配置并编译 `landlords_server`
3. 检查 ONNX 模型目录后启动服务端

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1
```

如果你只想先验证构建是否通过，不想立刻启动服务：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1 -BuildOnly
```

默认监听：

```text
TCP: LANDLORDS_HOST:LANDLORDS_PORT
WS : ws://LANDLORDS_HOST:LANDLORDS_WS_PORT/ws
```

### 2. 启动前端 Web

这个脚本会自动完成三件事：

1. 读取 `landlords.env`
2. 执行 `flutter build web --release`
3. 启动本地静态资源服务，并把 `/ws` 代理到 `LANDLORDS_BACKEND_WS_PROXY`

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_frontend_windows.ps1
```

如果你只想先验证前端构建：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_frontend_windows.ps1 -BuildOnly
```

启动后默认访问：

```text
http://LANDLORDS_WEB_HOST:LANDLORDS_WEB_PORT
```

## Linux 后端部署说明

仓库保留的自动化主脚本是 Windows 版；Linux 部署请直接使用 CMake 和环境变量。

最低建议准备：

```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build protobuf-compiler libprotobuf-dev libevent-dev
```

然后按 [`landlords.env`](landlords.env) 中的同名键准备环境，执行：

```bash
cmake -S backend/server -B backend/server/build \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLANDLORDS_ENABLE_ONNXRUNTIME=ON \
  -DLANDLORDS_ONNXRUNTIME_ROOT=/opt/onnxruntime/Microsoft.ML.OnnxRuntime.1.24.3

cmake --build backend/server/build --target landlords_server
```

ONNX 模型文件本身可以跨平台复用，详细见 [docs/onnx_deployment.md](docs/onnx_deployment.md)。

## ONNX 模型

仓库默认已经提供可直接部署的 ONNX 目录：

- `backend/ai_models/onnx/douzero_ADP`
- `backend/ai_models/onnx/sl`
- `backend/ai_models/onnx/douzero_WP`

如果你要自己从 checkpoint 重新导出 ONNX，请直接看 [docs/onnx_deployment.md](docs/onnx_deployment.md)。

## 部署后验证

推荐按下面顺序做最小验证：

1. 运行 `run_backend_windows.ps1 -BuildOnly`
2. 运行 `run_frontend_windows.ps1 -BuildOnly`
3. 依次启动后端和前端，确认 Web 首页可以打开并连上 `/ws`
4. 执行 `flutter test`

后端测试源码保留在 [`backend/server/tests`](backend/server/tests)，Flutter 回归和联机测试保留在 [`test`](test)。

## 文档导航

- [docs/configuration.md](docs/configuration.md)
- [docs/deployment.md](docs/deployment.md)
- [docs/onnx_deployment.md](docs/onnx_deployment.md)
- [docs/web_public_access.md](docs/web_public_access.md)
- [docs/architecture.md](docs/architecture.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
