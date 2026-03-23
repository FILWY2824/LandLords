# Flutter 客户端

`lib/` 是 Flutter 客户端主代码目录，面向 Web / Windows / Android 共用。

## 当前推荐运行方式

- Web：使用 [`run_frontend_windows.ps1`](../run_frontend_windows.ps1)
- Windows 桌面：使用标准 Flutter 命令 `flutter run -d windows`
- Android：使用标准 Flutter 命令 `flutter run -d android`

## 编译期配置来源

前端构建会读取 [`landlords.env`](../landlords.env) 中这些键：

- `LANDLORDS_WS_URL`
- `LANDLORDS_TCP_HOST`
- `LANDLORDS_TCP_PORT`
- `LANDLORDS_MOBILE_WS_URL`
- `LANDLORDS_GITHUB_REPO`
- `LANDLORDS_DOWNLOAD_URL`
