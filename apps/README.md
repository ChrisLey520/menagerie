# `apps/` — 小游戏应用目录

本仓库 **只维护一个 Godot 工程根**：[`sudoku/`](sudoku/)（目录名历史沿用）。其中已包含 **数独**，后续其它小游戏也在 **同一** `project.godot` 下以模块形式扩展（场景、脚本子目录等），**不要**在 `apps/` 下再建第二个并列的 Godot 项目。

## 当前 Godot 工程

| 目录 | 显示名 | 引擎 | 说明 |
|------|--------|------|------|
| [`sudoku/`](sudoku/) | Menagerie · 小游戏合集 | Godot 4.3+ | 唯一工程根；内含数独、消消乐（Match-3）及后续游戏模块 |

## 命名与结构建议

- 工程根目录名暂不强制重命名；新增游戏用 **模块 id**（小写、`kebab-case` 或单词）作为脚本/场景子路径（如 `scripts/snake/`、`scenes/snake/`）。
- `project.godot` 里 `application/config/name`：面向玩家与系统窗口标题的产品名，当前为 **Menagerie**。
