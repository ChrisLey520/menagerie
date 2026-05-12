extends RefCounted
class_name ThemePalette
## 自然系主题色（清新），用于 StyleBoxFlat / 字体色

const PALETTES := {
	"forest": {
		"bg_top": Color("e8f5ef"),
		"bg_bottom": Color("d4ebe0"),
		"panel": Color("f7fcf9"),
		"panel_border": Color("a8cfc0"),
		"primary": Color("2f6f55"),
		"muted": Color("5a7d72"),
		"grid_line": Color("8fb5a8"),
		"cell": Color("ffffff"),
		"cell_alt": Color("f0faf5"),
		"fixed": Color("c8e6d9"),
		"key_border": Color("c49a00"),
		"error": Color("c62828"),
		"accent": Color("3d8f73"),
	},
	"ocean": {
		"bg_top": Color("e6f4ff"),
		"bg_bottom": Color("cfe8fc"),
		"panel": Color("f7fbff"),
		"panel_border": Color("8ebfe0"),
		"primary": Color("1e5a8c"),
		"muted": Color("5a7a94"),
		"grid_line": Color("7aaed4"),
		"cell": Color("ffffff"),
		"cell_alt": Color("eef7ff"),
		"fixed": Color("c5dff5"),
		"key_border": Color("c49000"),
		"error": Color("c62828"),
		"accent": Color("2c8fce"),
	},
	"dawn": {
		"bg_top": Color("fff5e8"),
		"bg_bottom": Color("fce8d8"),
		"panel": Color("fffaf5"),
		"panel_border": Color("e0b898"),
		"primary": Color("8c5a2b"),
		"muted": Color("8a7265"),
		"grid_line": Color("d4b896"),
		"cell": Color("ffffff"),
		"cell_alt": Color("fff5eb"),
		"fixed": Color("f5dcc8"),
		"key_border": Color("b8860b"),
		"error": Color("c62828"),
		"accent": Color("d4835f"),
	},
	"dusk": {
		"bg_top": Color("f2eef8"),
		"bg_bottom": Color("e4dcf2"),
		"panel": Color("faf8fc"),
		"panel_border": Color("b9a8d4"),
		"primary": Color("4a3f75"),
		"muted": Color("6f6688"),
		"grid_line": Color("a898cc"),
		"cell": Color("ffffff"),
		"cell_alt": Color("f4f0fb"),
		"fixed": Color("dcd4f0"),
		"key_border": Color("9a7b00"),
		"error": Color("c62828"),
		"accent": Color("7e6bbd"),
	},
}


static func get_palette(theme_id: String) -> Dictionary:
	if PALETTES.has(theme_id):
		return PALETTES[theme_id]
	return PALETTES["forest"]
