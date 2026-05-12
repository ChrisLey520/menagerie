extends RefCounted
class_name TestSudokuSolver
## 求解器单元测试（validate、solve、无解分支）。


static func run_all() -> bool:
	var ok := true
	ok = _run("validate_partial_empty_ok", _test_validate_empty) and ok
	ok = _run("validate_partial_conflict_row", _test_conflict_row) and ok
	ok = _run("solve_known_matches_expected", _test_known_solution) and ok
	ok = _run("solve_impossible_returns_false", _test_impossible) and ok
	ok = _run("is_solvable_partial", _test_solvable_partial) and ok
	return ok


static func _run(name: String, fn: Callable) -> bool:
	var passed: bool = fn.call()
	if passed:
		print("[PASS] ", name)
	else:
		push_error("[FAIL] " + name)
	return passed


static func _test_validate_empty() -> bool:
	var g := PackedInt32Array()
	g.resize(81)
	for i in 81:
		g[i] = 0
	return SudokuSolver.validate_partial(g)


static func _test_conflict_row() -> bool:
	var g := PackedInt32Array()
	g.resize(81)
	for i in 81:
		g[i] = 0
	g[0] = 5
	g[1] = 5
	return not SudokuSolver.validate_partial(g)


static func _test_known_solution() -> bool:
	## 经典易题（公开测例）：有解且线索格保持不变
	var p := SudokuTestHelpers.grid_from_compact(
		"""
		530070000
		600195000
		098000060
		000260000
		000629010
		000037000
		060000028
		000419005
		000080079
		"""
	)
	var res := SudokuSolver.solve(p)
	if not res.get("ok", false):
		return false
	var sol: PackedInt32Array = res["solution"]
	if sol.size() != 81:
		return false
	if not SudokuTestHelpers.is_filled_valid(sol):
		return false
	return SudokuTestHelpers.clues_preserved(p, sol)


static func _test_impossible() -> bool:
	## 同行故意放置重复 + 其余兼容仍应无解（题目自相矛盾）
	var g := PackedInt32Array()
	g.resize(81)
	for i in 81:
		g[i] = 0
	g[0] = 1
	g[1] = 2
	g[2] = 3
	g[3] = 4
	g[4] = 5
	g[5] = 6
	g[6] = 7
	g[7] = 8
	g[8] = 1  ## 与 g[0] 冲突且该行已满无解扩展
	var res := SudokuSolver.solve(g)
	return not res.get("ok", false)


static func _test_solvable_partial() -> bool:
	var g := PackedInt32Array()
	g.resize(81)
	for i in 81:
		g[i] = 0
	g[0] = 5
	g[10] = 3
	return SudokuSolver.is_solvable(g)
