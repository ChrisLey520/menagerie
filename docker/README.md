# Docker 与 Web 端

Godot Web 导出物是 **静态文件**。本目录提供两种用法：

1. **仅托管**（你本机/CI 已手动导出，或从别处拿到 `index.html` 等）— 用现成 `web.docker-compose.yml` 挂卷。  
2. **在容器里完成「Godot 导出 + 运行」** — 用 `Dockerfile.web` 多阶段构建：第一阶段下载 Godot 4.3 + 导出模板并 `--export-release`，第二阶段 `nginx:alpine` 对外提供服务。**无需在本机安装 Godot**。

---

## 方式 A：仅托管已有导出目录（nginx 挂载）

前提：已有导出文件夹（含 `index.html`、`.wasm`、`.pck` / `.godot` 等）。

```bash
# 仓库根目录
mkdir -p web-export
# 将导出产物复制进 web-export/

docker compose -f docker/web.docker-compose.yml up
```

浏览器：**http://localhost:8080**

---

## 方式 B：Docker 内自动导出 Web 并启动（推荐「一条龙」）

前提：已安装 **Docker**（含 daemon），可执行 `docker compose`。

在 **仓库根目录** 执行：

```bash
docker compose -f docker/docker-compose.full-web.yml up --build
```

首次会较长时间（镜像内下载 Godot Linux 版 + 导出模板 + 执行导出）。完成后浏览器访问：**http://localhost:8080**

停止：`Ctrl+C` 或 `docker compose -f docker/docker-compose.full-web.yml down`。

等价底层命令（如需手写调试）：

```bash
docker build -f docker/Dockerfile.web -t menagerie-sudoku-web .
docker run --rm -p 8080:80 menagerie-sudoku-web
```

构建上下文为仓库根（见 [`Dockerfile.web`](Dockerfile.web) 中 `COPY apps/sudoku`）；忽略规则见根目录 [`.dockerignore`](../.dockerignore)。

### 说明与排错

- **导出预设**：工程内已有 [`apps/sudoku/export_presets.cfg`](../apps/sudoku/export_presets.cfg)，预设名为 **`Web`**，与 Dockerfile 中 `--export-release "Web"` 一致。若在本地升级 Godot 小版本后导出选项变更，可在编辑器里重新导出一次 Web，覆盖提交该文件。  
- **Godot 版本**：Dockerfile 默认使用官方 **Godot 4.3 stable** 下载地址；若要对齐其它 minor，请改 `Dockerfile.web` 里的 `GODOT_VERSION` / `RELEASE_NAME`，并确认「编辑器版本 ↔ 导出模板」成对一致。  
- **不要在浏览器里用 `file://` 打开导出目录**；必须通过 HTTP(S)，Docker + nginx 即满足。  
- **SharedArrayBuffer / COOP / COEP**：若浏览器控制台报线程或跨域隔离相关错误，可能需在 nginx 增加响应头；参见 Godot 文档 [Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)。当前镜像为默认 `nginx:alpine`，未附加自定义 `nginx.conf`；需要时可挂载自定义配置覆盖。
