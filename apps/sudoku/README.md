# Menagerie · 数独（Godot 4）

本目录为 **独立 Godot 应用**，隶属于仓库根目录的 [小游戏合集 Monorepo](../../README.md)。可单独用 Godot 打开本文件夹进行开发与导出；与后续其他游戏并行存在于 `apps/` 下。

使用 **Godot 4.3+** 与 **GDScript**，可选导出 **HTML5** 作为 H5。

## 运行

1. 安装 [Godot 4.3+](https://godotengine.org/download)（推荐与 `project.godot` 中 `config/features` 一致）。
2. 在 Godot 项目管理器中 **导入 `apps/sudoku` 目录**（不要指向仓库根目录）。
3. 首次打开会生成 `.godot/` 并导入翻译 CSV；按 **运行（F5）**。

## 功能概要

- **求解**：`scripts/sudoku/solver.gd` — MRV + 行/列/宫位掩码回溯。
- **出题**：`scripts/sudoku/generator.gd` — 对角三宫预填 + 洗牌回溯终盘，再随机挖空并保证 **至少一解**。
- **关卡**：`scripts/sudoku/levels.gd` — 5 档难度（给定格数量区间）。
- **钥匙**：钥匙模式下标记格子并输入数字；**解锁求解** 仅合并「题干 + 钥匙」，填满其余空格；冲突 / 无解有提示。
- **语言**：简体中文默认，`zh_TW`、`en`；设置写入 `user://settings.cfg`。
- **主题**：森林 / 海洋 / 晨曦 / 暮紫，持久化同上。

## 国际化

文案在 [`localization/translations.csv`](localization/translations.csv)，UTF-8。引擎默认语言见 `project.godot` → `internationalization/locale/fallback`（`zh_CN`）。

## Web（H5）导出

**项目 → 导出 → Web**，添加预设后导出。建议在触控设备上确认：格子与按钮 **最小约 44×44**（已在场景中设置 `custom_minimum_size`）。可按需在导出预设里开启 gzip、线程等选项。

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
| `scenes/main_menu.tscn` | 本应用主菜单（入口场景链至数独玩法） |
| `scenes/sudoku_game.tscn` | 数独主界面 |
| `scripts/game_settings.gd` | 自动加载：语言 / 主题持久化 |
| `scripts/themes/theme_palette.gd` | 主题色板 |
| `scripts/sudoku/*.gd` | 关卡表、求解器、生成器 |
| `tests/test_runner.tscn` | 自动化测试入口 |
| `tests/unit/*.gd` | 单元测试套件 |
