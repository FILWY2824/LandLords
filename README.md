# LandLords

一个为 `Web / Windows / Android` 设计的斗地主项目，当前仓库已经拆成前端展示层、共享协议层和 C++ 服务端层，便于后续继续迭代到真实联机版本。

现在已经补上：

- Flutter 原生端真实 `TCP + protobuf` 网关
- Flutter Web 真实 `WebSocket + protobuf` 网关
- C++ `libevent + protobuf` 服务端，提供 `TCP + WebSocket` 双入口
- 更完整的斗地主基础牌型支持
- 注册 / 登录 / 匹配 / 对局快照 / 重连 / 心跳
- 更接近主流斗地主产品风格的大厅和对局界面

## 目录结构

```text
lib/                     Flutter 客户端
lib/src/models           前端数据模型
lib/src/pages            登录 / 大厅 / 对局页面
lib/src/services         网关抽象与本地演示实现
lib/src/state            应用状态控制器

shared/proto             protobuf 协议定义

backend/server/include   C++ 服务端头文件
backend/server/src       C++ 服务端实现
backend/server/CMakeLists.txt

docs/                    架构说明
```

## 当前已完成

- Flutter 客户端拆分为登录、大厅、对局三层页面
- Windows / Android 走真实 protobuf 长连接
- 支持“机器人对战”和“在线玩家匹配”
- 对局页展示地主底牌、记牌器、本轮分数、倍率、最近动作
- C++ 服务端采用 `libevent + protobuf`
- 服务端支持注册、登录、机器人匹配、PVP 排队匹配、建房、发牌、基础出牌/不出、重连、心跳
- 当前已支持的牌型包括：单张、对子、三张、三带一、三带二、顺子、连对、飞机、飞机带单、飞机带对、炸弹、四带二、四带两对、王炸
- 已加入春天判定与结算倍率
- 用户数据暂存于本地文件，已经抽出仓储接口，未来可替换为 MySQL

## 如何运行

### 1. 先启动 C++ 服务端

第一次生成 VS2022 工程：

```bash
cmake -G "Visual Studio 17 2022" -A x64 -S backend/server -B backend/server/build-vs
```

编译 Debug：

```bash
cmake --build backend/server/build-vs --config Debug
```

编译成功后，服务端可执行文件在：

```text
backend/server/build-vs/Debug/landlords_server.exe
```

直接运行：

```bash
backend/server/build-vs/Debug/landlords_server.exe
```

默认监听：

```text
TCP: 127.0.0.1:23001
WebSocket: ws://127.0.0.1:23002/ws
```

用户文件默认写到：

```text
runtime/users.db
```

### 2. 启动 Flutter 客户端

仓库根目录执行。

Windows：

```bash
flutter run -d windows
```

Android：

```bash
flutter run -d android
```

Web：

```bash
flutter run -d chrome
```

### 3. 默认测试账号

你可以直接先注册一个账号，例如：

```text
用户名: player1
密码: 123456
```

如果服务端已经启动：

- Windows / Android 客户端会走真实 `TCP + protobuf`
- Web 客户端会走真实 `WebSocket + protobuf`

## Flutter 运行结果说明

- `与机器人对战`：客户端登录后向服务端发匹配请求，服务端创建两个机器人补位
- `在线玩家匹配`：服务端会将三个在线玩家放进同一房间
- 当前房间快照会实时推回客户端
- 连接断开后，客户端下次重连时会自动尝试按 `session_token + room_id` 取回房间快照

## C++ 服务端构建

Windows 下当前已经按你本机路径验证通过：

```bash
cmake -G "Visual Studio 17 2022" -A x64 -S backend/server -B backend/server/build-vs
cmake --build backend/server/build-vs --config Debug
```

默认会优先尝试使用：

```text
F:/PersonalProject/Linux/libevent/out/vs2022_64
```

Ubuntu 20.04 未来部署时，建议安装系统版依赖：

```bash
sudo apt install cmake g++ protobuf-compiler libprotobuf-dev libevent-dev
cmake -S backend/server -B backend/server/build -DLANDLORDS_USE_LOCAL_WINDOWS_DEPS=OFF
cmake --build backend/server/build
```

## 协议说明

- 协议文件：`shared/proto/landlords.proto`
- 传输方式：TCP 长连接 + 4 字节长度前缀 + protobuf 二进制消息
- 当前客户端为了保证 Flutter 端先能直接跑起来，默认接的是本地演示网关
- 原生端真实网关在 `lib/src/services/socket_game_gateway.dart`
- Web 端真实网关在 `lib/src/services/websocket_game_gateway.dart`

## 后续优先建议

1. 继续补牌型边界和完整竞赛规则校验
2. 引入断线托管、房间重放、观战
3. 将 `IUserRepository` 切换为 MySQL 实现
4. 拆出机器人策略模块，支持不同难度
5. 为 WebSocket 增加鉴权校验与跨域部署配置
