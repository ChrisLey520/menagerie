extends RefCounted
class_name Match3BoardModel
## 消消乐棋盘：纯数据与规则（无 Node），供 UI 与单元测试调用。

const ROWS := 8
const COLS := 8
const NUM_TYPES := 6
const EMPTY := -1

const TARGET_SCORE := 2000
const MOVES_START := 28
const HINTS_PER_GAME := 8

const SCORE_PER_GEM := 10
const COMBO_MULT_WAVE1 := 1.0
const COMBO_MULT_WAVE2 := 1.2
const COMBO_MULT_WAVE3_PLUS := 1.5

var rng: RandomNumberGenerator
var cells: PackedInt32Array = PackedInt32Array()
var score: int = 0
var moves_left: int = MOVES_START
var hints_left: int = HINTS_PER_GAME


func _init(p_rng: RandomNumberGenerator = null) -> void:
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()
	cells.resize(ROWS * COLS)


static func idx(r: int, c: int) -> int:
	return r * COLS + c


func in_bounds(r: int, c: int) -> bool:
	return r >= 0 and r < ROWS and c >= 0 and c < COLS


func new_game() -> void:
	score = 0
	moves_left = MOVES_START
	hints_left = HINTS_PER_GAME
	fill_board_no_matches()


## 单测注入盘面（须已满且无 EMPTY）
func set_cells_for_test(data: PackedInt32Array) -> void:
	if data.size() != ROWS * COLS:
		return
	cells = data.duplicate()


func fill_board_no_matches() -> void:
	var types: Array[int] = []
	types.resize(NUM_TYPES)
	for r in ROWS:
		for c in COLS:
			for t in NUM_TYPES:
				types[t] = t
			_shuffle_int_array_in_place(types, rng)
			var placed := false
			for t in types:
				if _can_place_no_match(r, c, t):
					cells[idx(r, c)] = t
					placed = true
					break
			if not placed:
				cells[idx(r, c)] = (r * COLS + c + 1) % NUM_TYPES


func _can_place_no_match(r: int, c: int, t: int) -> bool:
	if c >= 2 and cells[idx(r, c - 1)] == t and cells[idx(r, c - 2)] == t:
		return false
	if r >= 2 and cells[idx(r - 1, c)] == t and cells[idx(r - 2, c)] == t:
		return false
	return true


func _shuffle_int_array_in_place(arr: Array[int], p_rng: RandomNumberGenerator) -> void:
	var n := arr.size()
	for i in range(n - 1, 0, -1):
		var j := p_rng.randi_range(0, i)
		var tmp: int = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## 收集所有参与 ≥3 连线的格索引（不含 EMPTY）
static func find_match_indices(board: PackedInt32Array) -> Dictionary:
	var matched: Dictionary = {}
	if board.size() != ROWS * COLS:
		return matched
	for r in ROWS:
		var c := 0
		while c < COLS:
			var v: int = board[idx(r, c)]
			if v == EMPTY:
				c += 1
				continue
			var c2 := c
			while c2 < COLS and board[idx(r, c2)] == v:
				c2 += 1
			if c2 - c >= 3:
				for cc in range(c, c2):
					matched[idx(r, cc)] = true
			c = c2
	for c in COLS:
		var r := 0
		while r < ROWS:
			var v2: int = board[idx(r, c)]
			if v2 == EMPTY:
				r += 1
				continue
			var r2 := r
			while r2 < ROWS and board[idx(r2, c)] == v2:
				r2 += 1
			if r2 - r >= 3:
				for rr in range(r, r2):
					matched[idx(rr, c)] = true
			r = r2
	return matched


static func board_has_any_matches(board: PackedInt32Array) -> bool:
	return not find_match_indices(board).is_empty()


func has_matches() -> bool:
	return board_has_any_matches(cells)


## 临时交换后是否有匹配（用于合法交换判定）
func swap_creates_match(i: int, j: int) -> bool:
	if not _adjacent(i, j):
		return false
	var copy := cells.duplicate()
	var tmp: int = copy[i]
	copy[i] = copy[j]
	copy[j] = tmp
	return board_has_any_matches(copy)


func are_adjacent(i: int, j: int) -> bool:
	return _adjacent(i, j)


func _adjacent(i: int, j: int) -> bool:
	var r1 := i / COLS
	var c1 := i % COLS
	var r2 := j / COLS
	var c2 := j % COLS
	var dr := absi(r1 - r2)
	var dc := absi(c1 - c2)
	return dr + dc == 1


## 是否存在一步合法交换（用于死局洗牌）
func exists_valid_move() -> bool:
	for r in ROWS:
		for c in COLS:
			var i := idx(r, c)
			if c + 1 < COLS:
				var j := idx(r, c + 1)
				if swap_creates_match(i, j):
					return true
			if r + 1 < ROWS:
				var j2 := idx(r + 1, c)
				if swap_creates_match(i, j2):
					return true
	return false


## 返回首对可走步索引 [i,j]，若无则 [-1,-1]
func find_hint_pair() -> Vector2i:
	for r in ROWS:
		for c in COLS:
			var i := idx(r, c)
			if c + 1 < COLS:
				var j := idx(r, c + 1)
				if swap_creates_match(i, j):
					return Vector2i(i, j)
			if r + 1 < ROWS:
				var j2 := idx(r + 1, c)
				if swap_creates_match(i, j2):
					return Vector2i(i, j2)
	return Vector2i(-1, -1)


## 玩家交换：合法则扣步、交换并消除连锁；非法返回 false
func try_player_swap(i: int, j: int) -> bool:
	if moves_left <= 0:
		return false
	if not _adjacent(i, j):
		return false
	if not swap_creates_match(i, j):
		return false
	moves_left -= 1
	var tmp: int = cells[i]
	cells[i] = cells[j]
	cells[j] = tmp
	_resolve_all_chains()
	return true


func _resolve_all_chains() -> void:
	var wave := 0
	while true:
		var matched := find_match_indices(cells)
		if matched.is_empty():
			break
		wave += 1
		var mult := COMBO_MULT_WAVE1
		if wave == 2:
			mult = COMBO_MULT_WAVE2
		elif wave >= 3:
			mult = COMBO_MULT_WAVE3_PLUS
		var n := matched.size()
		score += int(round(float(n * SCORE_PER_GEM) * mult))
		for k in matched:
			cells[int(k)] = EMPTY
		_apply_gravity()
		_fill_empty_from_top()


func _apply_gravity() -> void:
	for c in COLS:
		var write_r := ROWS - 1
		for r in range(ROWS - 1, -1, -1):
			var v: int = cells[idx(r, c)]
			if v != EMPTY:
				cells[idx(write_r, c)] = v
				write_r -= 1
		while write_r >= 0:
			cells[idx(write_r, c)] = EMPTY
			write_r -= 1


func _fill_empty_from_top() -> void:
	for c in COLS:
		for r in ROWS:
			var i := idx(r, c)
			if cells[i] == EMPTY:
				cells[i] = _pick_spawn_type(r, c)


func _pick_spawn_type(r: int, c: int) -> int:
	var order: Array[int] = []
	order.resize(NUM_TYPES)
	for t in NUM_TYPES:
		order[t] = t
	_shuffle_int_array_in_place(order, rng)
	for t in order:
		if _spawn_ok(r, c, t):
			return t
	for t2 in NUM_TYPES:
		if not _would_horizontal_triple_at(r, c, t2):
			return t2
	return rng.randi_range(0, NUM_TYPES - 1)


func _spawn_ok(r: int, c: int, t: int) -> bool:
	if r + 1 < ROWS:
		var d1: int = cells[idx(r + 1, c)]
		var d2: int = cells[idx(r + 2, c)] if r + 2 < ROWS else EMPTY
		if d1 == t and d2 == t:
			return false
	if _would_horizontal_triple_at(r, c, t):
		return false
	return true


func _would_horizontal_triple_at(r: int, c: int, t: int) -> bool:
	var left1 := cells[idx(r, c - 1)] if c >= 1 else EMPTY
	var left2 := cells[idx(r, c - 2)] if c >= 2 else EMPTY
	if left1 == t and left2 == t:
		return true
	var right1 := cells[idx(r, c + 1)] if c + 1 < COLS else EMPTY
	if left1 == t and right1 == t:
		return true
	var right2 := cells[idx(r, c + 2)] if c + 2 < COLS else EMPTY
	if right1 == t and right2 == t:
		return true
	return false


func is_won() -> bool:
	return score >= TARGET_SCORE


func is_lost() -> bool:
	return moves_left <= 0 and not is_won()


## 洗牌直到无三连且存在可走步（或全板重生）
func shuffle_dead_board() -> void:
	var guard := 0
	while guard < 200:
		guard += 1
		_shuffle_all_filled_cells()
		if not has_matches() and exists_valid_move():
			return
	## 回退：全板重生
	fill_board_no_matches()
	if not exists_valid_move():
		## 极端情况再洗几次
		for _i in range(50):
			_shuffle_all_filled_cells()
			if not has_matches() and exists_valid_move():
				return


func _shuffle_all_filled_cells() -> void:
	var flat: Array[int] = []
	for i in cells.size():
		if cells[i] != EMPTY:
			flat.append(cells[i])
	if flat.is_empty():
		return
	for ii in range(flat.size() - 1, 0, -1):
		var jj := rng.randi_range(0, ii)
		var t: int = flat[ii]
		flat[ii] = flat[jj]
		flat[jj] = t
	var k := 0
	for i in cells.size():
		if cells[i] != EMPTY:
			cells[i] = flat[k]
			k += 1


func try_use_hint() -> Vector2i:
	if hints_left <= 0:
		return Vector2i(-1, -1)
	if not exists_valid_move():
		shuffle_dead_board()
	var p := find_hint_pair()
	if p.x < 0:
		return Vector2i(-1, -1)
	hints_left -= 1
	return p
