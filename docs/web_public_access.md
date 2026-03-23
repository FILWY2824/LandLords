# Web 对外访问

如果你希望别人通过浏览器直接访问项目，推荐使用仓库内的同源 Web 发布方式。

## 推荐链路

1. 启动后端：[`run_backend_windows.ps1`](../run_backend_windows.ps1)
2. 启动前端：[`run_frontend_windows.ps1`](../run_frontend_windows.ps1)
3. 把公网域名或反向代理指向 `http://127.0.0.1:<LANDLORDS_WEB_PORT>`

## 为什么推荐同源

- 浏览器页面和 `/ws` 走同一个入口，前端配置最简单
- Nginx、Caddy、Cloudflare Tunnel、FRP 都更容易接入
- 不需要把浏览器端写死到某个独立 WebSocket 地址

## 本地启动命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_backend_windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_frontend_windows.ps1
```

## 反向代理建议

把你的公网域名反向代理到：

```text
http://127.0.0.1:LANDLORDS_WEB_PORT
```

只要代理层允许 WebSocket Upgrade，浏览器端的 `/ws` 就会继续被转发到后端。
