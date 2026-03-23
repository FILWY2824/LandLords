# LandLords

面向 `Web / Windows / Android` 的斗地主联机项目。前端使用 Flutter，后端使用 `C++20 + libevent + protobuf`，机器人默认使用 `DouZero ONNX` 直接在 C++ 服务端进程内推理。

## 项目优势

- 开源部署入口已经收敛成一套正式配置文件 [`landlords.env`](landlords.env) 和两个 Windows 主脚本，不再要求用户自己拼命令。
- 后端依赖路径、前后端地址、端口、Web 代理、ONNX 模型目录都统一进配置文件，适合不同服务器环境直接改值部署。
- 默认提供 `easy / normal / hard` 三档 ONNX 模型目录，部署时可以直接用仓库内模型，也可以自行重新导出。
- 测试源码完整保留，方便部署后做联机验证；测试过程中产生的中间产物、日志和调试输出不再作为开源内容保留。

## 当前推荐入口

```text
landlords.env                  正式配置文件，用户直接修改
run_backend_windows.ps1        Windows 后端编译并运行脚本
run_frontend_windows.ps1       Windows 前端编译并运行脚本
docs/onnx_deployment.md        ONNX 导出与跨平台部署说明
```

模块入口：

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

下面这些信息来自当前仓库配置和本地实际检查，适合作为开源部署的推荐范围：

| 组件 | 推荐/已核实版本 | 说明 |
| --- | --- | --- |
| Flutter SDK | `3.38.9` | 由当前 Flutter SDK 本地仓库标签核实 |
| Dart SDK | `3.10.8` | 由 `dart --version` 核实 |
| CMake | `3.29.2` | 已实际用于当前后端配置与编译 |
| Visual Studio | `Visual Studio 2022` + `MSVC v143` | Windows 后端推荐环境 |
| Protobuf C++ | `3.20.x` 兼容版本 | 当前工程和生成代码按这一代版本兼容 |
| libevent | `2.1.x` | 需要可被 `find_package(Libevent CONFIG REQUIRED)` 发现 |
| ONNX Runtime | `1.24.3` | 当前默认配置路径对应此版本 |
| Python | `3.9.6+` | ONNX 导出与模型工具推荐 |
| Gradle | `8.14` | 来自 [`android/gradle/wrapper/gradle-wrapper.properties`](android/gradle/wrapper/gradle-wrapper.properties) |
| Android Gradle Plugin | `8.11.1` | 来自 [`android/settings.gradle.kts`](android/settings.gradle.kts) |
| Kotlin | `2.2.20` | 来自 [`android/settings.gradle.kts`](android/settings.gradle.kts) |
| JDK | `17` | Android 构建脚本要求 Java 17；本机若不是 17，请切换后再打 Android 包 |

## 部署前先改什么

直接编辑 [`landlords.env`](landlords.env)。用户不需要新建模板文件，也不需要自己补配置键。

第一次部署最需要确认的是这些键：

- `LANDLORDS_WINDOWS_DEPS_ROOT`
- `LANDLORDS_PROTOBUF_ROOT`
- `LANDLORDS_LIBEVENT_CMAKE_DIR`
- `LANDLORDS_ONNXRUNTIME_ROOT`
- `LANDLORDS_HOST`
- `LANDLORDS_PORT`
- `LANDLORDS_WS_PORT`
- `LANDLORDS_WEB_HOST`
- `LANDLORDS_WEB_PORT`
- `LANDLORDS_BACKEND_WS_PROXY`
- `LANDLORDS_TCP_HOST`
- `LANDLORDS_TCP_PORT`
- `LANDLORDS_MOBILE_WS_URL`

配置项详细说明见 [docs/configuration.md](docs/configuration.md)。

## Windows 部署

### 1. 启动后端

这个脚本会自动完成三件事：

1. 读取 `landlords.env`
2. 运行 CMake 配置并编译 `landlords_server`
3. 检查 ONNX 模型目录后启动服务端

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1
```

如果你只想先验证构建是否通过，不想立刻启动服务端：

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

## Linux 部署说明

仓库保留的自动化主脚本是 Windows 版。Linux 部署请直接使用 CMake 和环境变量。

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
  -DLANDLORDS_USE_LOCAL_WINDOWS_DEPS=OFF \
  -DLANDLORDS_ENABLE_ONNXRUNTIME=ON \
  -DLANDLORDS_ONNXRUNTIME_ROOT=/opt/onnxruntime/Microsoft.ML.OnnxRuntime.1.24.3

cmake --build backend/server/build --target landlords_server
```

ONNX 模型本身可以跨平台复用，详细见 [docs/onnx_deployment.md](docs/onnx_deployment.md)。

## ONNX 模型

仓库默认已经提供可直接部署的 ONNX 目录：

- `backend/ai_models/onnx/douzero_ADP`
- `backend/ai_models/onnx/sl`
- `backend/ai_models/onnx/douzero_WP`

如果你要自己从 checkpoint 导出新的 ONNX，请直接看 [docs/onnx_deployment.md](docs/onnx_deployment.md)。

## 部署后验证

推荐按下面顺序做最小验证：

1. 运行 `run_backend_windows.ps1 -BuildOnly`，确认后端编译通过
2. 运行 `run_frontend_windows.ps1 -BuildOnly`，确认前端编译通过
3. 依次启动后端和前端，确认 Web 首页可以打开并连上 `/ws`
4. 执行 `flutter test`

后端测试源码保留在 [`backend/server/tests`](backend/server/tests)；Flutter 联机和回归测试保留在 [`test`](test)。

## 文档导航

- [docs/configuration.md](docs/configuration.md)
- [docs/deployment.md](docs/deployment.md)
- [docs/onnx_deployment.md](docs/onnx_deployment.md)
- [docs/web_public_access.md](docs/web_public_access.md)
- [docs/architecture.md](docs/architecture.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
