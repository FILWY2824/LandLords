# C++ 服务端

`backend/server/` 是斗地主联机后端，使用 `C++20 + libevent + protobuf`。

## 目录说明

- `include/landlords/core`：基础配置、日志、通用模型
- `include/landlords/network`：TCP / WebSocket 网络层
- `include/landlords/game`：房间与对局逻辑
- `include/landlords/services`：登录、匹配、好友、邀请等业务
- `src`：实现代码
- `tests`：原生测试代码
- `generated`：protobuf C++ 生成文件

## Windows 构建与运行

从仓库根目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1
```

只验证构建：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1 -BuildOnly
```

## 关键配置

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
- `LANDLORDS_DOUZERO_ONNX_DIR_*`

## 测试代码

常见测试目标包括：

- `landlords_room_tests`
- `landlords_friend_center_tests`
- `landlords_room_lifecycle_tests`
- `landlords_onnx_tests`
