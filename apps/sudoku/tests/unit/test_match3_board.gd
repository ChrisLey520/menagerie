extends RefCounted
class_name TestMatch3Board
## Match3BoardModel 单元测试


static func run_all() -> bool:
	var ok := true
	ok = _run("regenerate_has_no_matches", _test_regenerate_no_matches) and ok
	ok = _run("invalid_swap_unchanged", _test_invalid_swap) and ok
	ok = _run("valid_swap_clears_and_scores", _test_valid_swap_scores) and ok
	ok = _run("regenerate_has_valid_move", _test_regenerate_has_move) and ok
	ok = _run("hint_finds_pair", _test_hint_pair) and ok
	return ok


static func _run(name: String, fn: Callable) -> bool:
	var passed: bool = fn.call()
	if passed:
		print("[PASS] ", name)
	else:
		push_error("[FAIL] " + name)
	return passed


static func _test_regenerate_no_matches() -> bool:
	var rng := RandomNumberGenerator.new()
	for seed in range(30):
		rng.seed = seed + 1000
		var m := Match3BoardModel.new(rng)
		m.new_game()
		if Match3BoardModel.board_has_any_matches(m.cells):
			return false
	return true


static func _test_invalid_swap() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var m := Match3BoardModel.new(rng)
	m.new_game()
	var snap := m.cells.duplicate()
	if not m.try_player_swap(0, 2):
		pass
	else:
		return false
	if m.cells != snap:
		return false
	if not m.try_player_swap(0, 0):
		pass
	return m.cells == snap


static func _test_valid_swap_scores() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var m := Match3BoardModel.new(rng)
	var b := PackedInt32Array()
	b.resize(64)
	for r in Match3BoardModel.ROWS:
		for c in Match3BoardModel.COLS:
			b[Match3BoardModel.idx(r, c)] = (r + c) % Match3BoardModel.NUM_TYPES
	b[Match3BoardModel.idx(4, 3)] = 2
	b[Match3BoardModel.idx(4, 4)] = 2
	b[Match3BoardModel.idx(4, 5)] = 5
	b[Match3BoardModel.idx(4, 6)] = 2
	if Match3BoardModel.board_has_any_matches(b):
		return false
	m.set_cells_for_test(b)
	m.moves_left = 5
	m.score = 0
	var i := Match3BoardModel.idx(4, 5)
	var j := Match3BoardModel.idx(4, 6)
	if not m.swap_creates_match(i, j):
		return false
	if not m.try_player_swap(i, j):
		return false
	if m.score < Match3BoardModel.SCORE_PER_GEM * 3:
		return false
	if Match3BoardModel.board_has_any_matches(m.cells):
		return false
	return true


static func _test_regenerate_has_move() -> bool:
	var rng := RandomNumberGenerator.new()
	for seed in range(50):
		rng.seed = seed + 5000
		var m := Match3BoardModel.new(rng)
		m.new_game()
		if not m.exists_valid_move():
			return false
	return true


static func _test_hint_pair() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var m := Match3BoardModel.new(rng)
	m.new_game()
	m.hints_left = 3
	var p := m.try_use_hint()
	if p.x < 0 or p.y < 0:
		return false
	if not m.swap_creates_match(p.x, p.y):
		return false
	return true
