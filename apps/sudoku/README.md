# Menagerie · Godot 合集工程（Godot 4）

本目录是仓库内 **唯一 Godot 工程根**（`project.godot` 在此），隶属于根目录的 [小游戏合集 Monorepo](../../README.md)。**数独** 为当前已接入的游戏之一；后续其它小游戏也在 **本工程内** 以模块形式扩展，见 [docs/adding-a-game.md](../../docs/adding-a-game.md)。目录名 `sudoku` 为历史沿用，不代表「仅数独工程」。

使用 **Godot 4.3+** 与 **GDScript**，可选导出 **HTML5** 作为 H5。

## 运行

1. 安装 [Godot 4.3+](https://godotengine.org/download)（推荐与 `project.godot` 中 `config/features` 一致）。
2. 在 Godot 项目管理器中 **导入本目录 `apps/sudoku`**（不要指向仓库根目录）。
3. 首次打开会生成 `.godot/` 并导入翻译 CSV；按 **运行（F5）**。

## 功能概要

- **求解**：`scripts/sudoku/solver.gd` — MRV + 行/列/宫位掩码回溯。
- **出题**：`scripts/sudoku/generator.gd` — 对角三宫预填 + 洗牌回溯终盘，再随机挖空并保证 **至少一解**。
- **关卡**：`scripts/sudoku/levels.gd` — 5 档难度（给定格数量区间）。
- **自定线索**：在「自定线索模式」下标记空格并填入你已确定的数字；**解锁求解** 合并题干与你的线索后填满其余格；冲突 / 无解有提示。主菜单可填写 **自定模式名称**（持久化）覆盖按钮文案。
- **语言**：简体中文默认，`zh_TW`、`en`；设置写入 `user://settings.cfg`。
- **主题**：森林 / 海洋 / 晨曦 / 暮紫，持久化同上。

## 国际化

文案在 [`localization/translations.csv`](localization/translations.csv)，UTF-8；表头语言代码须与代码中 `GameSettings.LOCALE_IDS` 一致（`zh_CN` / `zh_TW` / `en`）。引擎默认语言见 `project.godot` → `internationalization/locale/fallback`（`zh_CN`）。首次导入工程后应在编辑器 **项目 → 本地化** 中确认翻译资源已生成。

## Web（H5）导出

**项目 → 导出 → Web**，添加预设后导出。建议在触控设备上确认：棋盘与数字键随窗口缩放，格子 **最小约 44×44**。可按需在导出预设里开启 gzip、线程等选项。

## 自动化测试

无插件、纯 GDScript，入口场景 [`tests/test_runner.tscn`](tests/test_runner.tscn)：

- **求解器**：`validate_partial`、经典易题求解与线索保留、矛盾题无解、部分格可解。
- **生成器**：随机终盘合法、`generate_for_level` 可解、`make_puzzle` 在给定目标内挖空仍可解。

在本目录下执行（需 Godot 在 `PATH` 或通过 `GODOT` 指定）：

```bash
cd apps/sudoku
chmod +x scripts/run_tests.sh   # 首次
./scripts/run_tests.sh
```

或在仓库根目录使用快捷脚本：

```bash
./scripts/run-sudoku-tests.sh
```

退出码：`0` 全部通过，`非 0` 存在失败。

CI：仓库根 [`.github/workflows/godot-tests.yml`](../../.github/workflows/godot-tests.yml) 会在 `apps/sudoku` 目录下执行同上命令。

## 目录说明

| 路径 | 说明 |
|------|------|
| `scenes/main_menu.tscn` | 合集主菜单（入口链至数独等玩法） |
| `scenes/sudoku_game.tscn` | 数独主界面 |
| `scripts/game_settings.gd` | 自动加载：语言 / 主题持久化 |
| `scripts/themes/theme_palette.gd` | 主题色板 |
| `scripts/sudoku/*.gd` | 关卡表、求解器、生成器 |
| `tests/test_runner.tscn` | 自动化测试入口 |
| `tests/unit/*.gd` | 单元测试套件 |
