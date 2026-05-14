extends RefCounted
class_name Match3GemPalette
## 消消乐六色宝石填充色（跨主题固定糖果色）


const GEM_FILL_COLORS: Array[Color] = [
	Color("#e8b849"),
	Color("#d94f7a"),
	Color("#3b82c4"),
	Color("#7c4ddb"),
	Color("#3faa7a"),
	Color("#e0702c"),
]


static func fill_for_type(t: int) -> Color:
	if t < 0 or t >= GEM_FILL_COLORS.size():
		return Color("#888888")
	return GEM_FILL_COLORS[t]


static func border_for_type(t: int) -> Color:
	return fill_for_type(t).darkened(0.22)
