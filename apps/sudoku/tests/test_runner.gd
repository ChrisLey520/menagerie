extends Node
## 无头自动化测试入口：运行结束后 `get_tree().quit(code)`，供 CI / `scripts/run_tests.sh` 判断成败。


func _ready() -> void:
	var ok := true
	ok = TestSudokuSolver.run_all() and ok
	ok = TestSudokuGenerator.run_all() and ok
	if ok:
		print("=== Sudoku automation tests: ALL PASSED ===")
	else:
		push_error("=== Sudoku automation tests: SOME FAILED ===")
	get_tree().quit(0 if ok else 1)
