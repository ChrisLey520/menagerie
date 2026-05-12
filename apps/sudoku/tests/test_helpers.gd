extends RefCounted
class_name SudokuTestHelpers
## 测试用：紧凑字符串 ↔ PackedInt32Array（81，行优先；允许换行与空格）


static func grid_from_compact(s: String) -> PackedInt32Array:
	var cleaned := ""
	for ch in s:
		if ch == " " or ch == "\n" or ch == "\r" or ch == ".":
			continue
		if ch >= "0" and ch <= "9":
			cleaned += ch
	var g := PackedInt32Array()
	g.resize(81)
	var n := mini(cleaned.length(), 81)
	for i in n:
		g[i] = cleaned.substr(i, 1).to_int()
	for i in range(n, 81):
		g[i] = 0
	return g


static func count_clues(grid: PackedInt32Array) -> int:
	var c := 0
	for i in grid.size():
		if grid[i] >= 1 and grid[i] <= 9:
			c += 1
	return c


static func is_filled_valid(grid: PackedInt32Array) -> bool:
	if grid.size() != 81:
		return false
	for i in 81:
		if grid[i] < 1 or grid[i] > 9:
			return false
	return SudokuSolver.validate_partial(grid)


static func clues_preserved(puzzle: PackedInt32Array, solution: PackedInt32Array) -> bool:
	for i in 81:
		if puzzle[i] != 0 and puzzle[i] != solution[i]:
			return false
	return true
