---
name: menagerie-docker-web
description: >-
  Starts or restarts the Menagerie Godot Web build (single repo Godot project
  under apps/sudoku, includes Sudoku and future mini-games) via Docker Compose
  (Godot headless export inside the image + nginx). Use when the user asks to
  run, start, restart, preview, or deploy the web version locally; mentions
  Docker for this repo; port 8080; or “一条龙” Web without installing Godot.
---

# Menagerie · Web 启动（Docker）

## 前提

- 已安装 **Docker**（daemon 运行中），可用 `docker compose`。
- 所有 `docker compose` 命令均在 **仓库根目录**（含 `apps/`、`docker/` 的那一层）执行。

## 推荐：容器内导出 + nginx（无需本机 Godot）

首次构建会下载 Godot 与导出模板，可能较久。

```bash
cd /path/to/menagerie
docker compose -f docker/docker-compose.full-web.yml up --build
```

- 浏览器：**http://localhost:8080**
- 后台运行：`docker compose -f docker/docker-compose.full-web.yml up -d --build`
- 停止：`docker compose -f docker/docker-compose.full-web.yml down`

## 重启（不重建镜像）

代码未改 Dockerfile / 导出流程时：

```bash
docker compose -f docker/docker-compose.full-web.yml down
docker compose -f docker/docker-compose.full-web.yml up -d
```

改了合集 Godot 工程 `apps/sudoku` 且需重新导出 Web 时，用 `up --build` 或显式 `docker compose ... build --no-cache` 后再 `up`。

## 备选：只托管已有静态导出

若已有 `index.html`、`.wasm`、`.pck` 等导出物：

```bash
mkdir -p web-export
# 将导出产物复制到 web-export/
docker compose -f docker/web.docker-compose.yml up
```

同样访问 **http://localhost:8080**（见 `docker/web.docker-compose.yml` 端口映射）。

## 代理须知

- 导出预设名为 **`Web`**，与 `apps/sudoku/export_presets.cfg` 及 `docker/Dockerfile.web` 一致。
- 不要用 `file://` 打开导出目录；必须通过 HTTP(S)。
- 细节与排错见仓库 **[docker/README.md](../../../docker/README.md)** 与根目录 **[README.md](../../../README.md)** 中「用 Docker 跑 Web 端」小节。
