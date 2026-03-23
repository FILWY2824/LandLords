# 架构说明

## 总体分层

项目按下面的方向组织：

1. `lib/` 负责 Flutter 客户端 UI、状态管理和网关抽象
2. `shared/proto/` 负责跨端共享协议
3. `backend/server/` 负责联机服务端、房间状态、持久化和机器人驱动
4. `backend/ai_service/` 负责 Python 侧的 DouZero 训练辅助、代理和导出
5. `backend/ai_models/` 存放可直接部署的 ONNX 模型

## Flutter 客户端

主要目录：

- `lib/src/pages`
- `lib/src/state`
- `lib/src/services`
- `lib/src/models`
- `lib/src/widgets`

职责：

- `pages/`：页面结构与交互
- `state/`：应用控制器与状态流转
- `services/`：TCP / WebSocket / 本地演示网关
- `models/`：UI 侧数据模型
- `widgets/`：跨页面复用组件

## C++ 服务端

主要目录：

- `backend/server/include/landlords/core`
- `backend/server/include/landlords/network`
- `backend/server/include/landlords/game`
- `backend/server/include/landlords/services`
- `backend/server/include/landlords/persistence`
- `backend/server/src`

职责：

- `core/`：配置、日志、基础模型
- `network/`：libevent 服务器、TCP/WS 连接、protobuf 编解码
- `game/`：房间状态、发牌、叫分、出牌、托管
- `services/`：登录、匹配、房间管理、好友、邀请
- `persistence/`：文件存储接口和实现

## 协议层

协议文件位于：

- `shared/proto/landlords.proto`

使用方式：

- Flutter 使用生成后的 Dart 文件
- C++ 服务端使用生成后的 `landlords.pb.h/.cc`
- Python 代理使用生成后的 `landlords_pb2.py`

## AI 层

当前支持两条路径：

1. `C++ + ONNX Runtime` 进程内推理
2. `Python DouZero Proxy` 代理推理

默认部署建议走第一条，第二条更适合训练、导出、实验不同 baseline。
