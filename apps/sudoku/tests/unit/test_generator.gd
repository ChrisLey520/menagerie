extends RefCounted
class_name TestSudokuGenerator
## 生成器单元测试（完整终盘、关卡出题、挖空）。


static func run_all() -> bool:
	var ok := true
	ok = _run("generate_full_grid_nonempty_valid", _test_full_grid) and ok
	ok = _run("generate_for_level_is_solvable", _test_level_puzzle) and ok
	ok = _run("make_puzzle_reduces_clues", _test_make_puzzle) and ok
	return ok


static func _run(name: String, fn: Callable) -> bool:
	var passed: bool = fn.call()
	if passed:
		print("[PASS] ", name)
	else:
		push_error("[FAIL] " + name)
	return passed


static func _test_full_grid() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var full := SudokuGenerator.generate_full_grid(rng)
	if full.size() != 81:
		return false
	return SudokuTestHelpers.is_filled_valid(full)


static func _test_level_puzzle() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var p := SudokuGenerator.generate_for_level(2, rng)
	if p.size() != 81:
		return false
	return SudokuSolver.is_solvable(p)


static func _test_make_puzzle() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	var full := SudokuGenerator.generate_full_grid(rng)
	if full.is_empty():
		return false
	var puzzle := SudokuGenerator.make_puzzle(full, 35, rng)
	var clue_after := SudokuTestHelpers.count_clues(puzzle)
	## 挖空后给定数应不超过目标，且仍可解
	return clue_after <= 35 and SudokuSolver.is_solvable(puzzle)
