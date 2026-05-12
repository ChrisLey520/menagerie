# 新增一个小游戏应用（Monorepo 约定）

在 **`apps/<game-id>/`** 下新建 **独立的 Godot 工程**，与现有游戏并行存在，互不强依赖。

## 推荐步骤

1. **建目录**：例如 `apps/snake/`。
2. **初始化 Godot 项目**：在该目录放置 `project.godot`、默认图标与入口场景；`run/main_scene` 指向本应用的主菜单或直接进入游戏。
3. **应用内 README**：说明如何运行、导出、测试命令（若有）。
4. **根目录登记**：在仓库根 [`README.md`](../README.md) 与 [`apps/README.md`](../apps/README.md) 的应用表中追加一行。
5. **CI（可选）**：在 [`.github/workflows/`](../.github/workflows/) 中为该应用增加 job，或扩展矩阵（下载一次 Godot，多个 `--path apps/<game-id>` 跑测试）。

## 与 `packages/shared` 的关系

跨游戏复用的 GDScript、主题、插件封装等放在 [`packages/shared/`](../packages/shared/)，由各应用在 Godot 中按需引用（导入路径、UID、或文档约定的拷贝策略需在引入时写清）。

## 与「合集启动器」的关系

若日后增加 **合集 Hub 应用**（一个 Godot 工程内按按钮启动其它导出包），通常单独放在例如 `apps/hub/`，通过 URL Scheme、平台商店分包或 Web 内链跳转分发；本仓库当前 **不强制** Hub，各 `apps/*` 仍可单独上架。
