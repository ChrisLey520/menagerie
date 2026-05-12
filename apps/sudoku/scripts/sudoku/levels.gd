extends RefCounted
class_name SudokuLevels
## 内置关卡难度：给定数字区间（越高越难 → 给定越少）

static var LEVELS: Array[Dictionary] = [
	{"id": "1", "given_min": 36, "given_max": 40},
	{"id": "2", "given_min": 34, "given_max": 38},
	{"id": "3", "given_min": 30, "given_max": 34},
	{"id": "4", "given_min": 26, "given_max": 30},
	{"id": "5", "given_min": 22, "given_max": 26},
]


static func level_count() -> int:
	return LEVELS.size()


static func get_level(idx: int) -> Dictionary:
	return LEVELS[clampi(idx, 0, LEVELS.size() - 1)]
