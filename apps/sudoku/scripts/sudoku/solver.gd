extends RefCounted
class_name SudokuSolver
## MRV + 行/列/宫位掩码回溯（9×9 数独）

const SIZE := 9
const CELL_COUNT := 81
const ALL_MASK := 0x1FF  ## 位 0..8 对应数字 1..9


static func _popcount(x: int) -> int:
	var n := 0
	var v := x
	while v > 0:
		n += 1
		v &= v - 1
	return n


static func _box_index(r: int, c: int) -> int:
	return (r / 3) * 3 + (c / 3)


## 已填格是否彼此冲突（不检查空位）
static func validate_partial(grid: PackedInt32Array) -> bool:
	if grid.size() != CELL_COUNT:
		return false
	var rows: Array[int] = []
	var cols: Array[int] = []
	var boxes: Array[int] = []
	rows.resize(SIZE)
	cols.resize(SIZE)
	boxes.resize(SIZE)
	for i in SIZE:
		rows[i] = 0
		cols[i] = 0
		boxes[i] = 0
	for i in CELL_COUNT:
		var v := grid[i]
		if v < 1 or v > 9:
			continue
		var bit := 1 << (v - 1)
		var r := i / SIZE
		var c := i % SIZE
		var b := _box_index(r, c)
		if rows[r] & bit:
			return false
		if cols[c] & bit:
			return false
		if boxes[b] & bit:
			return false
		rows[r] |= bit
		cols[c] |= bit
		boxes[b] |= bit
	return true


static func _build_masks(grid: PackedInt32Array) -> Array:
	var row_mask: Array[int] = []
	var col_mask: Array[int] = []
	var box_mask: Array[int] = []
	row_mask.resize(SIZE)
	col_mask.resize(SIZE)
	box_mask.resize(SIZE)
	for i in SIZE:
		row_mask[i] = 0
		col_mask[i] = 0
		box_mask[i] = 0
	for i in CELL_COUNT:
		var v := grid[i]
		if v < 1 or v > 9:
			continue
		var bit := 1 << (v - 1)
		var r := i / SIZE
		var c := i % SIZE
		var b := _box_index(r, c)
		row_mask[r] |= bit
		col_mask[c] |= bit
		box_mask[b] |= bit
	return [row_mask, col_mask, box_mask]


static func _candidates_at(row_mask: Array, col_mask: Array, box_mask: Array, idx: int) -> int:
	var r := idx / SIZE
	var c := idx % SIZE
	var b := _box_index(r, c)
	return ALL_MASK & ~(row_mask[r] | col_mask[c] | box_mask[b])


static func _dfs(grid: PackedInt32Array, row_mask: Array, col_mask: Array, box_mask: Array) -> bool:
	var best_idx := -1
	var best_cnt := 10
	for i in CELL_COUNT:
		if grid[i] != 0:
			continue
		var cand := _candidates_at(row_mask, col_mask, box_mask, i)
		var cnt := _popcount(cand)
		if cnt == 0:
			return false
		if cnt < best_cnt:
			best_cnt = cnt
			best_idx = i
	if best_idx < 0:
		return true
	var cand2 := _candidates_at(row_mask, col_mask, box_mask, best_idx)
	var br := best_idx / SIZE
	var bc := best_idx % SIZE
	var bb := _box_index(br, bc)
	var bit := 1
	for d in range(1, 10):
		if cand2 & bit:
			grid[best_idx] = d
			var dm := bit
			row_mask[br] |= dm
			col_mask[bc] |= dm
			box_mask[bb] |= dm
			if _dfs(grid, row_mask, col_mask, box_mask):
				return true
			row_mask[br] ^= dm
			col_mask[bc] ^= dm
			box_mask[bb] ^= dm
			grid[best_idx] = 0
		bit <<= 1
	return false


## 返回 { "ok": bool, "solution": PackedInt32Array }（solution 仅当 ok）
static func solve(grid: PackedInt32Array) -> Dictionary:
	var g := grid.duplicate()
	if not validate_partial(g):
		return {"ok": false}
	var masks := _build_masks(g)
	var row_mask: Array = masks[0]
	var col_mask: Array = masks[1]
	var box_mask: Array = masks[2]
	if _dfs(g, row_mask, col_mask, box_mask):
		return {"ok": true, "solution": g}
	return {"ok": false}


static func is_solvable(grid: PackedInt32Array) -> bool:
	var r := solve(grid)
	return r.get("ok", false)
