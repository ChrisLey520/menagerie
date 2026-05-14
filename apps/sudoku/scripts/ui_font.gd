extends RefCounted
class_name UiFont
## Web/桌面默认字体往往缺中文字形；统一使用 Noto Sans SC 避免方块/糊成一团

const FONT_PATH := "res://fonts/NotoSansSC-Regular.otf"

static var _font: Font


static func get_font() -> Font:
	if _font != null:
		return _font
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH) as Font
	return _font


static func bind_control(c: Control) -> void:
	var f := get_font()
	if f == null:
		return
	c.add_theme_font_override("font", f)


## 递归绑定 Label / Button / LineEdit / OptionButton（含对话框子节点）
static func bind_tree(root: Node) -> void:
	var f := get_font()
	if f == null:
		return
	_bind_recursive(root, f)


static func _bind_recursive(n: Node, f: Font) -> void:
	for c in n.get_children():
		if c is Label:
			(c as Label).add_theme_font_override("font", f)
		elif c is Button:
			(c as Button).add_theme_font_override("font", f)
		elif c is LineEdit:
			(c as LineEdit).add_theme_font_override("font", f)
		elif c is OptionButton:
			# 勿对 OptionButton 本体 set font：Web 导出下会破坏收起态选中项回显（空白）
			bind_option_button_popup(c as OptionButton)
		_bind_recursive(c, f)


## OptionButton 展开列表是独立 PopupMenu，不会继承按钮上的字体，必须单独设置（否则中文易乱码）
static func bind_option_button_popup(ob: OptionButton, font_size: int = 17) -> void:
	var f := get_font()
	if f == null:
		return
	var pop := ob.get_popup()
	if pop == null:
		return
	pop.add_theme_font_override("font", f)
	pop.add_theme_font_size_override("font_size", font_size)


## 按钮/下拉框在 hover、pressed 等状态也固定为主题文字色
static func style_control_text(control: Control, pal: Dictionary) -> void:
	control.add_theme_color_override("font_color", pal["primary"])
	control.add_theme_color_override("font_hover_color", pal["primary"])
	control.add_theme_color_override("font_pressed_color", pal["primary"])
	control.add_theme_color_override("font_focus_color", pal["primary"])
	control.add_theme_color_override("font_disabled_color", pal["muted"])


## 主色按钮上的字色（on_accent）
static func style_control_text_on_accent(control: Control, pal: Dictionary) -> void:
	var on := pal["on_accent"] as Color
	control.add_theme_color_override("font_color", on)
	control.add_theme_color_override("font_hover_color", on)
	control.add_theme_color_override("font_pressed_color", on)
	control.add_theme_color_override("font_focus_color", on)
	control.add_theme_color_override("font_disabled_color", pal["muted"])


## 统一下拉框弹层文字/底色，避免浅色主题下回显或选项文字过淡
static func style_option_button(ob: OptionButton, pal: Dictionary, font_size: int = 17) -> void:
	bind_option_button_popup(ob, font_size)
	style_control_text(ob, pal)

	var pop := ob.get_popup()
	if pop == null:
		return
	pop.add_theme_color_override("font_color", pal["primary"])
	pop.add_theme_color_override("font_hover_color", pal["primary"])
	pop.add_theme_color_override("font_focus_color", pal["primary"])
	pop.add_theme_color_override("font_disabled_color", pal["muted"])
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = pal["panel"]
	popup_panel.set_corner_radius_all(12)
	popup_panel.border_width_left = 1
	popup_panel.border_width_top = 1
	popup_panel.border_width_right = 1
	popup_panel.border_width_bottom = 1
	popup_panel.border_color = pal["panel_border"]
	pop.add_theme_stylebox_override("panel", popup_panel)
	var popup_hover := StyleBoxFlat.new()
	popup_hover.bg_color = (pal["panel_border"] as Color).lerp(pal["panel"] as Color, 0.65)
	popup_hover.set_corner_radius_all(10)
	pop.add_theme_stylebox_override("hover", popup_hover)


## 输入框也显式绑定浅色主题下的文字、占位符和底色
static func style_line_edit(edit: LineEdit, pal: Dictionary) -> void:
	bind_control(edit)
	edit.add_theme_color_override("font_color", pal["primary"])
	edit.add_theme_color_override("font_placeholder_color", pal["muted"])
	edit.add_theme_color_override("caret_color", pal["accent"])
	edit.add_theme_color_override("selection_color", (pal["accent"] as Color).lightened(0.55))
	var input_panel := StyleBoxFlat.new()
	input_panel.bg_color = pal["panel"]
	input_panel.set_corner_radius_all(12)
	input_panel.border_width_left = 1
	input_panel.border_width_top = 1
	input_panel.border_width_right = 1
	input_panel.border_width_bottom = 1
	input_panel.border_color = pal["panel_border"]
	var focus_sb := input_panel.duplicate() as StyleBoxFlat
	focus_sb.border_color = pal["accent"]
	focus_sb.border_width_left = 2
	focus_sb.border_width_top = 2
	focus_sb.border_width_right = 2
	focus_sb.border_width_bottom = 2
	edit.add_theme_stylebox_override("normal", input_panel.duplicate())
	edit.add_theme_stylebox_override("focus", focus_sb)


static func bind_option_popups_in_tree(root: Node, font_size: int = 17) -> void:
	var f := get_font()
	if f == null:
		return
	_bind_popup_recursive(root, f, font_size)


static func _bind_popup_recursive(n: Node, f: Font, font_size: int) -> void:
	if n is OptionButton:
		var pop := (n as OptionButton).get_popup()
		if pop:
			pop.add_theme_font_override("font", f)
			pop.add_theme_font_size_override("font_size", font_size)
	for c in n.get_children():
		_bind_popup_recursive(c, f, font_size)
