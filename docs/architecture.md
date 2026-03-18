# 架构说明

## 1. 分层目标

这个仓库按“协议共享、前后端分离、存储可替换”的思路组织：

- Flutter 只关心页面状态与网关接口，不直接耦合后端实现细节
- C++ 服务端按网络层、业务层、持久化层拆分
- protobuf 协议单独存放，供未来 Dart / C++ / 其他客户端共享

## 2. Flutter 端

主要文件：

- `lib/src/app.dart`
- `lib/src/state/app_controller.dart`
- `lib/src/services/game_gateway.dart`
- `lib/src/services/local_demo_gateway.dart`
- `lib/src/pages/*.dart`

职责划分：

- `pages/`：纯界面和交互
- `state/`：页面状态流转、异常提示、忙碌状态
- `services/`：后端访问抽象
- `models/`：UI 与网关共享的数据模型

后续接真实服务端时，建议新增：

- `lib/src/services/protobuf_socket_gateway.dart`
- `lib/src/services/protocol/` 目录存放 Dart 侧生成的 protobuf 文件

## 3. C++ 服务端

主要目录：

- `backend/server/include/landlords/network`
- `backend/server/include/landlords/services`
- `backend/server/include/landlords/game`
- `backend/server/include/landlords/persistence`
- `backend/server/src`

职责划分：

- `network/`：libevent TCP 长连接、protobuf 帧解包与回包
- `services/`：登录、匹配、房间调度、消息分发
- `game/`：房间状态、发牌、基础牌型校验、机器人回合驱动
- `persistence/`：用户存储接口与文件实现
- `core/`：公共模型、配置、工具函数

## 4. 存储替换策略

当前使用：

- `FileUserRepository`

未来切换 MySQL 时：

1. 新增 `MysqlUserRepository : IUserRepository`
2. 保持 `GameService` 不变
3. 只在 `main.cpp` 中替换依赖注入

## 5. 网络协议

当前消息流：

1. 客户端发送 `ClientMessage`
2. 服务端解析长度前缀 + protobuf
3. `GameService` 根据 oneof 分发
4. 服务端回 `ServerMessage`

已定义消息包括：

- 注册 / 登录
- 匹配请求
- 匹配成功推送
- 房间快照
- 出牌 / 不出
- 统一错误响应

## 6. 当前边界

这版重点是搭完整可演进骨架，因此服务端规则暂时与 Flutter 演示版保持一致，只实现：

- 单张
- 对子
- 三张
- 顺子
- 炸弹
- 王炸

如果要继续往正式商业斗地主靠拢，下一阶段建议优先补牌型引擎和断线重连。 
