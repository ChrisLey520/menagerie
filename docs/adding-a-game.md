# 新增一个小游戏（Monorepo 约定）

所有小游戏与数独 **共用** 仓库内 **唯一** Godot 工程，根目录为 [`apps/sudoku/`](../apps/sudoku/)（名称历史沿用，实为 Menagerie 合集工程）。新游戏在该工程 **内部** 增加资源与入口，不新建第二个 `project.godot`。

## 推荐步骤

1. **规划模块路径**：例如 `scripts/<game-id>/`、`scenes/<game-id>/`；与数独的 `scripts/sudoku/` 等并列，避免随意混放在根级脚本目录。
2. **接入主流程**：在主菜单或合集 Hub 场景中增加入口（`SceneTree.change_scene_to_*`、子视口或 UI 栈等，由实现选定）；`project.godot` 的 `run/main_scene` 仍指向合集总入口，一般 **不** 为单个小游戏单独改主场景文件路径为新游戏独占。
3. **模块内 README（可选）**：复杂游戏可在其脚本目录旁放简短说明（运行路径、关键场景名）。
4. **根目录登记**：在仓库根 [`README.md`](../README.md) 与 [`apps/README.md`](../apps/README.md) 的应用表中追加一行或更新「应用一览」。
5. **CI（可选）**：在 [`.github/workflows/`](../.github/workflows/) 中扩展测试步骤；仍使用 **`working-directory: apps/sudoku`** 与同一 `godot --path .`，可增加 `res://tests/<game>_runner.tscn` 或由现有 `test_runner` 编排。

## 与 `packages/shared` 的关系

跨游戏复用的 GDScript、主题、插件封装等放在 [`packages/shared/`](../packages/shared/)，由合集 Godot 工程按需引用（导入路径、UID、或文档约定的拷贝策略需在引入时写清）。

## 与「合集启动器」的关系

合集级主菜单 / Hub **即** 本工程内场景（例如当前主菜单与数独的切换）。若日后需要「外链跳转其它已单独导出的分包」，仍可在本工程内做 URL / 深链按钮；**不** 通过再建 `apps/hub/project.godot` 作为第二个工程来承载本仓库内小游戏，除非有独立于 Menagerie 合集的单独产品决策（届时再改文档）。
