# 部署说明

这份文档按“用户照着做即可部署成功”的顺序整理。

## 1. 拉取代码

```bash
git clone <your-repo-url>
cd LandLords
```

## 2. 修改正式配置文件

直接编辑仓库根目录的 [`landlords.env`](../landlords.env)。

第一次部署必须优先确认：

- `LANDLORDS_WINDOWS_DEPS_ROOT`
- `LANDLORDS_ONNXRUNTIME_ROOT`
- `LANDLORDS_HOST`
- `LANDLORDS_PORT`
- `LANDLORDS_WS_PORT`
- `LANDLORDS_WEB_HOST`
- `LANDLORDS_WEB_PORT`
- `LANDLORDS_BACKEND_WS_PROXY`

## 3. Windows 后端部署

### 环境要求

- Visual Studio 2022
- Desktop development with C++
- CMake 3.20+
- Protobuf C++ 3.20.x 兼容版本
- libevent 2.1.x
- ONNX Runtime 1.24.3

### 一条命令完成配置、编译、运行

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1
```

这个脚本会自动：

1. 读取 `landlords.env`
2. 校验 protobuf、libevent、onnxruntime 路径
3. 执行 CMake configure
4. 编译 `landlords_server`
5. 校验 ONNX 模型目录
6. 启动服务

### 只验证构建

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1 -BuildOnly
```

### 启动后的默认访问方式

```text
TCP: LANDLORDS_HOST:LANDLORDS_PORT
WS : ws://LANDLORDS_HOST:LANDLORDS_WS_PORT/ws
```

## 4. Windows 前端 Web 部署

### 一条命令完成构建和运行

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_frontend_windows.ps1
```

这个脚本会自动：

1. 读取 `landlords.env`
2. 执行 `flutter build web --release`
3. 启动本地静态资源服务
4. 把 `/ws` 代理到 `LANDLORDS_BACKEND_WS_PROXY`

### 只验证前端构建

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_frontend_windows.ps1 -BuildOnly
```

### 访问地址

```text
http://LANDLORDS_WEB_HOST:LANDLORDS_WEB_PORT
```

## 5. Linux 后端部署

项目保留的自动化入口是 Windows 版；Linux 部署请直接用 CMake。

### 依赖安装建议

```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build protobuf-compiler libprotobuf-dev libevent-dev
```

### 推荐配置

```env
LANDLORDS_CMAKE_GENERATOR=Ninja
LANDLORDS_CMAKE_BUILD_TYPE=Release
LANDLORDS_CMAKE_BUILD_DIR=backend/server/build
LANDLORDS_USE_LOCAL_WINDOWS_DEPS=OFF
LANDLORDS_ENABLE_ONNXRUNTIME=ON
LANDLORDS_ONNXRUNTIME_ROOT=/opt/onnxruntime/Microsoft.ML.OnnxRuntime.1.24.3
LANDLORDS_HOST=0.0.0.0
LANDLORDS_PORT=23001
LANDLORDS_WS_PORT=23002
```

### 手动构建命令

```bash
cmake -S backend/server -B backend/server/build \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLANDLORDS_USE_LOCAL_WINDOWS_DEPS=OFF \
  -DLANDLORDS_ENABLE_ONNXRUNTIME=ON \
  -DLANDLORDS_ONNXRUNTIME_ROOT=/opt/onnxruntime/Microsoft.ML.OnnxRuntime.1.24.3

cmake --build backend/server/build --target landlords_server
```

### 手动运行

把 `landlords.env` 中对应键导入到 Linux 环境后，再运行生成的 `landlords_server`。

## 6. Windows / Android 客户端补充说明

仓库不再保留单独的 Windows 打包脚本和 Android 打包脚本，避免入口过多。

如果你需要额外构建：

- Windows 客户端：`flutter run -d windows` 或 `flutter build windows`
- Android 客户端：`flutter run -d android` 或 `flutter build apk --debug`

Android 打包前请确认本机使用的是 JDK 17，因为当前 Android 工程配置固定到 Java 17。

## 7. 部署后验证

推荐依次执行：

1. `run_backend_windows.ps1 -BuildOnly`
2. `run_frontend_windows.ps1 -BuildOnly`
3. 启动后端
4. 启动前端
5. `flutter test`

如果要做更细的联机验证，可以使用 [`tool`](../tool) 目录下保留的 smoke 脚本。
