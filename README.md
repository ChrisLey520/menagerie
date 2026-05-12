# Menagerie · 小游戏合集（Monorepo）

本仓库采用 **monorepo**：根目录只放约定、文档与 CI；**每个小游戏是一个可独立导出、独立发布的 Godot 工程**，位于 [`apps/`](apps/) 下。

| 目录 | 说明 |
|------|------|
| [`apps/`](apps/) | 各小游戏独立应用（各自包含 `project.godot`） |
| [`packages/shared/`](packages/shared/) | 预留：跨应用复用的脚本 / 资源 / 插件封装 |
| [`docs/`](docs/) | 仓库级说明（如新增游戏的约定） |
| [`.github/workflows/`](.github/workflows/) | CI（按应用目录运行测试或扩展为矩阵） |

## 注意事项（请先读）

- **在 Godot 里应打开子应用目录，不要打开仓库根目录**  
  根目录下没有 `project.godot`，无法作为 Godot 工程运行。开发、运行、导出某个游戏时，请在 Godot 项目管理器中选择 **该游戏所在文件夹**（例如数独：[`apps/sudoku`](apps/sudoku)），使编辑器使用的工程根为 `apps/<游戏名>/`。

- **每个游戏自成一个 Godot 项目**  
  新增游戏时，在 [`apps/`](apps/) 下新建独立子目录，并在其中放置该游戏自己的 `project.godot`、场景与脚本。不要假设「在根目录能统一跑所有游戏」；合集关系由本仓库的目录与文档约定体现，工程之间不强制绑在一个 Godot 项目里。

- **自动化测试以应用目录为工作目录**  
  数独的测试在 [`apps/sudoku`](apps/sudoku) 下执行；仓库根目录的 [`scripts/run-sudoku-tests.sh`](scripts/run-sudoku-tests.sh) 会转调到该目录。CI 同样使用 `apps/sudoku` 作为 `--path`（见 [`.github/workflows/godot-tests.yml`](.github/workflows/godot-tests.yml)）。

- **更多游戏与共享代码**  
  增加新游戏的步骤见 [docs/adding-a-game.md](docs/adding-a-game.md)。跨游戏复用内容计划放在 [`packages/shared`](packages/shared)；具体引用方式在真正接入时再写在对应应用的 README 里。

## 应用一览

| 应用 | 路径 | 说明 |
|------|------|------|
| **数独** | [`apps/sudoku/`](apps/sudoku/) | Godot 4.3+；MRV 求解、关卡生成、钥匙解锁、多主题与 i18n |

后续新游戏在 `apps/<game-id>/` 新增独立工程即可，不与现有游戏强制耦合。

## 克隆后怎么用

- **开发 / 运行 / 导出数独**：在 Godot 中 **导入或打开** 目录 [`apps/sudoku`](apps/sudoku)（见上文「注意事项」）。详细功能与导出说明见该目录下的 [apps/sudoku/README.md](apps/sudoku/README.md)。
- **跑数独自动化测试**（需本机已安装 Godot 4.3+，可执行文件名为 `godot` 且在 `PATH` 中，或通过环境变量 `GODOT` 指定完整路径）：

```bash
./scripts/run-sudoku-tests.sh
```

## 常见问题：不安装 Godot，能否导出 Web 并启动？

分两件事说清楚：**生成 Web 包（导出）** 和 **在浏览器里运行已经生成好的包**。

### 导出（生成 HTML5 / WASM 等产物）

**不能**在「完全不运行 Godot」的前提下，单靠克隆本仓库就自动生成 Web 包。Godot 的 Web 导出必须由 **Godot 编辑器对应的导出流程** 完成——典型做法是：

- 本机安装 [Godot 编辑器](https://godotengine.org/download)，在 **项目 → 导出** 里配置 Web 预设并导出；或  
- 在 **CI（如 GitHub Actions）或 Docker** 里下载 **Godot 无头（headless）可执行文件 + 导出模板**，用命令行 `--export-release` 生成产物（这样你个人电脑可以不装 Godot，但云端仍会执行 Godot）。

仓库当前 **未内置**「一键在 CI 里导出 Web」的工作流；若需要，可以后续增加 Action：在流水线里拉取 Godot、写入/使用 `export_presets.cfg`，再把构建结果打成 Artifact 或发到 Pages。

### 启动（本地预览已经导出的 Web 包）

**可以**，且 **不需要** 安装 Godot。导出完成后得到的是静态文件（如 `index.html`、`.wasm`、`.pck` / `.godot` 等，以你导出预设为准），用任意 **静态 HTTP 服务** 打开目录即可，例如：

```bash
cd /path/to/exported_folder
python3 -m http.server 8080
# 浏览器访问 http://localhost:8080
```

或使用 `npx serve` 等工具。**不要用 `file://` 直接双击打开**，多数浏览器对 WASM/线程限制会导致 Godot Web 导出无法正常跑。

### 用 Docker 跑 Web 端

**可以。** 有两种常见做法（详见 **[docker/README.md](docker/README.md)**）：

1. **只托管**：你自己或其它流水线已经导出好静态文件，放进 **`web-export/`**，再运行 [`docker/web.docker-compose.yml`](docker/web.docker-compose.yml)（仅 nginx 挂载目录）。  
2. **一条龙（不在本机安装 Godot）**：用 **[`docker/docker-compose.full-web.yml`](docker/docker-compose.full-web.yml)**（或同目录下的 [`Dockerfile.web`](docker/Dockerfile.web)）在镜像里 **下载 Godot + 导出模板 → headless 导出 Web → nginx 对外提供服务**。构建需要联网拉取官方 Godot 与模板；运行浏览器访问 **http://localhost:8080**。

数独工程已包含 Web 导出预设 [`apps/sudoku/export_presets.cfg`](apps/sudoku/export_presets.cfg)（预设名 **`Web`**），供 Docker 内 `godot --export-release "Web"` 使用。

### 小结

| 你想做的事 | 是否必须本机安装 Godot |
|------------|-------------------------|
| 从源码 **编译/导出** Web 包 | 否（可用 CI/Docker 代跑），但必须 **在某处** 执行 Godot 导出流程 |
| **运行** 已经导出好的 Web 包 | 否（只需静态服务器 + 浏览器） |

## 文档

- [新增一个小游戏应用（约定）](docs/adding-a-game.md)
- [应用索引](apps/README.md)
