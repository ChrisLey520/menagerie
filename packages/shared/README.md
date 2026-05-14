# `packages/shared`

预留目录：用于存放 **合集 Godot 工程与其它包之间复用** 的内容，例如：

- 通用 UI 组件（Godot 场景 / 脚本）
- 通用音频、字体、Shader
- 封装后的自动加载单例（需在 [`apps/sudoku/project.godot`](../apps/sudoku/project.godot) 中按需显式配置）

当前暂无强制结构；引入共享包时在合集工程 [apps/sudoku/README.md](../apps/sudoku/README.md) 或模块说明中注明依赖方式。
