extends Node
## 无头自动化测试入口：运行结束后 `get_tree().quit(code)`，供 CI / `scripts/run_tests.sh` 判断成败（数独 + 消消乐等合集模块）。

const _TestSudokuSolver := preload("res://tests/unit/test_solver.gd")
const _TestSudokuGenerator := preload("res://tests/unit/test_generator.gd")
const _TestMatch3Board := preload("res://tests/unit/test_match3_board.gd")


func _ready() -> void:
	var ok := true
	ok = _TestSudokuSolver.run_all() and ok
	ok = _TestSudokuGenerator.run_all() and ok
	ok = _TestMatch3Board.run_all() and ok
	if ok:
		print("=== Menagerie Godot automation tests: ALL PASSED ===")
	else:
		push_error("=== Menagerie Godot automation tests: SOME FAILED ===")
	get_tree().quit(0 if ok else 1)
