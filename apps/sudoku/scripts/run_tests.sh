#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "错误：未找到 Godot 可执行文件。请安装 Godot 4.3+ 或将 GODOT 设为完整路径。" >&2
	echo "示例：GODOT=/Applications/Godot.app/Contents/MacOS/Godot $0" >&2
	exit 127
fi
exec "$GODOT" --headless --path "$ROOT" "res://tests/test_runner.tscn"
