# protobuf 协议

协议源文件：

- `shared/proto/landlords.proto`

## 当前用途

- C++ 服务端消息定义
- Flutter 客户端消息定义
- Python ONNX 导出/校验工具使用的消息定义

## 当前生成产物

- C++：`backend/server/generated/`
- Dart：`lib/src/proto/`
- Python：`backend/ai_service/douzero_onnx/generated/`

## 版本说明

当前仓库内生成的 C++ 代码与 `protobuf 3.20.3` 兼容。

## 协议变更后要做什么

协议变更后，请同步更新三端生成文件，并确认：

- 服务端仍能编译
- Flutter 端仍能运行
- Python ONNX 工具仍能解析对应消息
