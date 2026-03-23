# 贡献说明

欢迎提交 issue、文档修正、功能改进和 bugfix。

## 提交前建议

1. 先复制并检查 `landlords.env`
2. 确认你的改动不会重新引入机器相关的硬编码路径、地址或端口
3. 如果改动涉及部署流程，请同步更新 `README.md` 或 `docs/`
4. 如果改动涉及协议、房间流程或好友/邀请逻辑，请补充测试或 smoke 验证

## 建议自检

```powershell
flutter test
powershell -NoProfile -ExecutionPolicy Bypass -File .\check_landlords_ports.ps1
```

如已编译后端测试目标，还建议执行：

```powershell
.\backend\server\build-vs\Debug\landlords_room_tests.exe
.\backend\server\build-vs\Debug\landlords_friend_center_tests.exe
.\backend\server\build-vs\Debug\landlords_room_lifecycle_tests.exe
.\backend\server\build-vs\Debug\landlords_onnx_tests.exe
```

## 文档要求

涉及下面这些内容的改动，请同步更新 Markdown：

- 配置项
- 构建步骤
- 部署步骤
- 模块目录
- 脚本入口
