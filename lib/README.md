# Flutter 客户端

`lib/` 是 Flutter 客户端主代码目录。当前仓库维护的正式发布路径只有 Web，对外入口是 [`run_frontend_windows.ps1`](../run_frontend_windows.ps1)。

## 当前推荐运行方式

- Web：使用 [`run_frontend_windows.ps1`](../run_frontend_windows.ps1)

仓库已经移除了 Android / Windows 客户端工程目录，因此移动端和桌面端不再属于当前正式开源部署流程。

## 编译期配置来源

前端构建会读取 [`landlords.env`](../landlords.env) 中这些键：

- `LANDLORDS_WS_URL`
- `LANDLORDS_GITHUB_REPO`
- `LANDLORDS_DOWNLOAD_URL`
