extends RefCounted
class_name SudokuGenerator
## 对角三宫随机预填 + 回溯洗牌填满终盘 → 随机挖空并校验有解

const SIZE := 9
const CELL_COUNT := 81
const ALL_MASK := 0x1FF


static func _shuffle_digits(rng: RandomNumberGenerator) -> PackedInt32Array:
	var a := PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9])
	for i in range(8, 0, -1):
		var j := rng.randi_range(0, i)
		var t := a[i]
		a[i] = a[j]
		a[j] = t
	return a


static func _box_start(box_idx: int) -> Vector2i:
	var br := box_idx / 3
	var bc := box_idx % 3
	return Vector2i(bc * 3, br * 3)


static func _fill_box(grid: PackedInt32Array, box_idx: int, perm: PackedInt32Array) -> void:
	var start := _box_start(box_idx)
	var k := 0
	for dy in 3:
		for dx in 3:
			var r := start.y + dy
			var c := start.x + dx
			grid[r * SIZE + c] = perm[k]
			k += 1


static func _box_index(r: int, c: int) -> int:
	return (r / 3) * 3 + (c / 3)


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


static func _fill_remaining(grid: PackedInt32Array, rng: RandomNumberGenerator, row_mask: Array, col_mask: Array, box_mask: Array, cell_idx: int) -> bool:
	if cell_idx >= CELL_COUNT:
		return true
	if grid[cell_idx] != 0:
		return _fill_remaining(grid, rng, row_mask, col_mask, box_mask, cell_idx + 1)
	var r := cell_idx / SIZE
	var c := cell_idx % SIZE
	var b := _box_index(r, c)
	var cand := ALL_MASK & ~(row_mask[r] | col_mask[c] | box_mask[b])
	var digits: Array[int] = []
	var bit := 1
	for d in range(1, 10):
		if cand & bit:
			digits.append(d)
		bit <<= 1
	for i in range(digits.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := digits[i]
		digits[i] = digits[j]
		digits[j] = t
	for d in digits:
		var dm := 1 << (d - 1)
		grid[cell_idx] = d
		row_mask[r] |= dm
		col_mask[c] |= dm
		box_mask[b] |= dm
		if _fill_remaining(grid, rng, row_mask, col_mask, box_mask, cell_idx + 1):
			return true
		row_mask[r] ^= dm
		col_mask[c] ^= dm
		box_mask[b] ^= dm
		grid[cell_idx] = 0
	return false


## 生成完整合法终盘
static func generate_full_grid(rng: RandomNumberGenerator) -> PackedInt32Array:
	var attempt_max := 50
	for _a in attempt_max:
		var grid := PackedInt32Array()
		grid.resize(CELL_COUNT)
		for i in CELL_COUNT:
			grid[i] = 0
		for box_idx in [0, 4, 8]:
			_fill_box(grid, box_idx, _shuffle_digits(rng))
		var masks := _build_masks(grid)
		var row_m: Array = masks[0]
		var col_m: Array = masks[1]
		var box_m: Array = masks[2]
		if _fill_remaining(grid, rng, row_m, col_m, box_m, 0):
			return grid
	return PackedInt32Array()


static func _count_filled(grid: PackedInt32Array) -> int:
	var n := 0
	for i in CELL_COUNT:
		if grid[i] >= 1 and grid[i] <= 9:
			n += 1
	return n


## 挖空至目标给定数（给定格数量），保证至少一解
static func make_puzzle(full: PackedInt32Array, given_target: int, rng: RandomNumberGenerator) -> PackedInt32Array:
	var puzzle := full.duplicate()
	var indices: Array[int] = []
	for i in CELL_COUNT:
		indices.append(i)
	for i in range(CELL_COUNT - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := indices[i]
		indices[i] = indices[j]
		indices[j] = tmp
	for idx in indices:
		if _count_filled(puzzle) <= given_target:
			break
		var backup := puzzle[idx]
		if backup == 0:
			continue
		puzzle[idx] = 0
		if not SudokuSolver.is_solvable(puzzle):
			puzzle[idx] = backup
	return puzzle


## 按关卡索引（0 起）生成一盘新题
static func generate_for_level(level_idx: int, rng: RandomNumberGenerator) -> PackedInt32Array:
	var cfg := SudokuLevels.get_level(level_idx)
	var target := rng.randi_range(cfg["given_min"], cfg["given_max"])
	for _i in 30:
		var full := generate_full_grid(rng)
		if full.is_empty():
			continue
		var puzzle := make_puzzle(full, target, rng)
		if not puzzle.is_empty() and SudokuSolver.is_solvable(puzzle):
			return puzzle
	return PackedInt32Array()
