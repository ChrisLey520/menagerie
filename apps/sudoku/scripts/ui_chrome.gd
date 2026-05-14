extends RefCounted
class_name UiChrome
## 统一卡片、主次按钮、Toast 的 StyleBox，与 ThemePalette 配套

const RADIUS_CARD := 16
const RADIUS_CTRL := 12
const SHADOW_SIZE := 10
const SHADOW_OFFSET := Vector2i(0, 4)


static func style_card_panel(pc: PanelContainer, pal: Dictionary) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = pal["card"]
	sb.set_corner_radius_all(RADIUS_CARD)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = pal["card_border"]
	sb.shadow_color = pal["shadow"] as Color
	sb.shadow_size = SHADOW_SIZE
	sb.shadow_offset = SHADOW_OFFSET
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	pc.add_theme_stylebox_override("panel", sb)


static func _flat_box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border
	return sb


## 次级：顶栏、工具栏、数字键盘、收起态 OptionButton
static func style_secondary_control(c: Control, pal: Dictionary) -> void:
	var r := RADIUS_CTRL
	var n := _flat_box(pal["panel"] as Color, pal["panel_border"] as Color, r)
	var h := _flat_box(pal["panel_hover"] as Color, pal["panel_border"] as Color, r)
	var p := _flat_box(pal["panel_pressed"] as Color, pal["panel_border"] as Color, r)
	c.add_theme_stylebox_override("normal", n)
	c.add_theme_stylebox_override("hover", h)
	c.add_theme_stylebox_override("pressed", p)
	c.add_theme_stylebox_override("focus", n.duplicate())
	UiFont.style_control_text(c, pal)


## 主 CTA：填充 accent 链 + on_accent 字色
static func style_primary_button(btn: Button, pal: Dictionary) -> void:
	var r := RADIUS_CTRL
	var n := _flat_box(pal["accent"] as Color, pal["accent_pressed"] as Color, r)
	n.border_width_left = 0
	n.border_width_top = 0
	n.border_width_right = 0
	n.border_width_bottom = 0
	var h := _flat_box(pal["accent_hover"] as Color, pal["accent_hover"] as Color, r)
	h.border_width_left = 0
	h.border_width_top = 0
	h.border_width_right = 0
	h.border_width_bottom = 0
	var pr := _flat_box(pal["accent_pressed"] as Color, pal["accent_pressed"] as Color, r)
	pr.border_width_left = 0
	pr.border_width_top = 0
	pr.border_width_right = 0
	pr.border_width_bottom = 0
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", n.duplicate())
	UiFont.style_control_text_on_accent(btn, pal)


## 主菜单主按钮：浅底 + 2px 主题色描边 + menu_play_text
static func _menu_play_box(bg: Color, border_col: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border_col
	return sb


static func style_menu_play_button(btn: Button, pal: Dictionary) -> void:
	var r := RADIUS_CTRL
	var n := _menu_play_box(pal["menu_play_bg"] as Color, pal["accent"] as Color, r)
	var h := _menu_play_box(pal["menu_play_bg_hover"] as Color, pal["accent_hover"] as Color, r)
	var p := _menu_play_box(pal["menu_play_bg_pressed"] as Color, pal["accent_pressed"] as Color, r)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus", n.duplicate())
	UiFont.style_control_text_color(
		btn, pal["menu_play_text"] as Color, pal["menu_subtitle"] as Color
	)


## 主菜单次级控件（语言 / 主题下拉）
static func style_menu_secondary_control(c: Control, pal: Dictionary) -> void:
	var rad := RADIUS_CTRL
	var n := _flat_box(pal["menu_panel"] as Color, pal["menu_panel_border"] as Color, rad)
	var h := _flat_box(pal["menu_panel_hover"] as Color, pal["menu_panel_border"] as Color, rad)
	var p := _flat_box(pal["menu_panel_pressed"] as Color, pal["menu_panel_border"] as Color, rad)
	c.add_theme_stylebox_override("normal", n)
	c.add_theme_stylebox_override("hover", h)
	c.add_theme_stylebox_override("pressed", p)
	c.add_theme_stylebox_override("focus", n.duplicate())
	UiFont.style_control_text_color(c, pal["menu_option_fg"] as Color, pal["menu_subtitle"] as Color)


## KeyMode 开启：底 fixed、描边 accent
static func style_key_mode_button_active(btn: Button, pal: Dictionary) -> void:
	var sb := _flat_box(pal["fixed"] as Color, pal["accent"] as Color, RADIUS_CTRL)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	btn.add_theme_stylebox_override("normal", sb.duplicate())
	btn.add_theme_stylebox_override("hover", sb.duplicate())
	btn.add_theme_stylebox_override("pressed", sb.duplicate())
	btn.add_theme_stylebox_override("focus", sb.duplicate())
	UiFont.style_control_text(btn, pal)


static func style_toast_label(lbl: Label, pal: Dictionary) -> void:
	lbl.add_theme_color_override("font_color", pal["primary"])
	var sb := StyleBoxFlat.new()
	sb.bg_color = pal["card"]
	sb.set_corner_radius_all(12)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = pal["panel_border"]
	sb.shadow_color = pal["shadow"] as Color
	sb.shadow_size = SHADOW_SIZE
	sb.shadow_offset = SHADOW_OFFSET
	sb.content_margin_left = 12
	sb.content_margin_top = 8
	sb.content_margin_right = 12
	sb.content_margin_bottom = 8
	lbl.add_theme_stylebox_override("normal", sb)


## 数独页顶栏 / 工具栏 / 第二行按钮与下拉
static func style_sudoku_toolbars(root: VBoxContainer, pal: Dictionary) -> void:
	for path in ["TopBar", "Toolbar", "Toolbar2"]:
		var row := root.get_node_or_null(path) as HBoxContainer
		if row == null:
			continue
		for ch in row.get_children():
			if ch is OptionButton:
				style_secondary_control(ch as Control, pal)
				UiFont.style_option_button(ch as OptionButton, pal, 17)
			elif ch is Button:
				var btn := ch as Button
				if btn.name == "KeyModeBtn" and btn.button_pressed:
					style_key_mode_button_active(btn, pal)
				else:
					style_secondary_control(btn, pal)


## 数字键盘与清除键
static func style_numpad(grid: GridContainer, pal: Dictionary) -> void:
	for ch in grid.get_children():
		if ch is Button:
			style_secondary_control(ch as Control, pal)
