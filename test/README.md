# 测试说明

`test/` 目录主要是 Flutter 侧的 widget、控制器和联机场景回归测试。

## 当前覆盖范围

- 房间流程
- 邀请流程
- 好友中心
- 在线状态
- 对局视图
- 对话框交互

## 配置来源

集成测试会读取：

- `LANDLORDS_TEST_HOST`
- `LANDLORDS_TEST_TCP_PORT`
- `LANDLORDS_TEST_WS_PORT`

因此你可以在不同机器上复用同一套测试，只需要调整 `landlords.env`。
