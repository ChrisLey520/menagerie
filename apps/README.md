# `apps/` — 独立小游戏应用

每个子目录 **必须** 是一个完整的 Godot 项目根目录（含 `project.godot`），可单独打开、单独导出 Web / 桌面 / 移动端。

## 当前应用

| 目录 | 显示名 | 引擎 |
|------|--------|------|
| [`sudoku/`](sudoku/) | Menagerie · 数独 | Godot 4.3+ |

## 命名建议

- 目录名：小写英文、`kebab-case` 或单个单词（如 `sudoku`、`snake`）。
- `project.godot` 里 `application/config/name`：面向玩家的应用名（可与仓库系列名 Menagerie 组合）。
