extends Control
## 数独：棋盘、关卡、自定线索模式、解锁求解

const CELL_COUNT := 81
const BOARD_H_MARGIN := 12
const MIN_CELL_PX := 44

var _rng := RandomNumberGenerator.new()

var _initial: PackedInt32Array = PackedInt32Array()
var _player: PackedInt32Array = PackedInt32Array()
var _key_marks: PackedByteArray = PackedByteArray() ## 0/1
var _key_digits: PackedInt32Array = PackedInt32Array()

var _level_idx: int = 0
var _focused: int = -1
var _key_mode: bool = false

var _cell_buttons: Array[Button] = []

@onready var _pal: Dictionary = ThemePalette.get_palette(GameSettings.theme_id)


func _ready() -> void:
	_rng.randomize()
	GameSettings.theme_changed.connect(_on_theme_changed)
	GameSettings.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	call_deferred("_boot_initial_ui")


func _boot_initial_ui() -> void:
	_build_ui()
	_apply_theme_background()
	UiFont.bind_tree(self)
	UiFont.bind_option_popups_in_tree(self, 17)
	_new_game()
	call_deferred("_fit_sudoku_grid")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_fit_sudoku_grid")


func _on_viewport_resized() -> void:
	call_deferred("_fit_sudoku_grid")


func _on_theme_changed(_id: String) -> void:
	_apply_theme_background()
	_pal = ThemePalette.get_palette(GameSettings.theme_id)
	_style_toolbar_and_pad()
	_refresh_all_cells()


func _on_locale_changed(_code: String) -> void:
	_apply_all_texts()
	var loc := get_node_or_null("RootVB/TopBar/LocaleOption") as OptionButton
	if loc:
		var idx := GameSettings.locale_display_index(GameSettings.locale_code)
		if idx >= 0:
			loc.select(idx)


func _fill_locale_option_items(opt: OptionButton) -> void:
	opt.clear()
	opt.add_item(tr("LANG_ZH_CN"))
	opt.add_item(tr("LANG_ZH_TW"))
	opt.add_item(tr("LANG_EN"))


func _on_locale_picked(idx: int) -> void:
	if idx >= 0 and idx < GameSettings.LOCALE_IDS.size():
		GameSettings.locale_code = GameSettings.LOCALE_IDS[idx]


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()
	var theme_bg := ColorRect.new()
	theme_bg.name = "ThemeBg"
	theme_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	theme_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(theme_bg)
	var root_vb := VBoxContainer.new()
	root_vb.name = "RootVB"
	root_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vb.add_theme_constant_override("separation", 12)
	add_child(root_vb)
	var safe_bottom := 28
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.add_theme_constant_override("separation", 10)
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := Button.new()
	back.name = "BackBtn"
	back.text = tr("BTN_BACK")
	back.custom_minimum_size = Vector2(76, 44)
	back.pressed.connect(_on_back)
	back.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(back)
	var title := Label.new()
	title.name = "Title"
	title.text = tr("SUDOKU_TITLE")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	top_bar.add_child(title)
	var loc := OptionButton.new()
	loc.name = "LocaleOption"
	loc.custom_minimum_size = Vector2(138, 44)
	loc.size_flags_horizontal = Control.SIZE_SHRINK_END
	_fill_locale_option_items(loc)
	var li := GameSettings.locale_display_index(GameSettings.locale_code)
	loc.select(li if li >= 0 else 0)
	loc.item_selected.connect(_on_locale_picked)
	loc.add_theme_font_size_override("font_size", 16)
	top_bar.add_child(loc)
	root_vb.add_child(top_bar)
	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.add_theme_constant_override("separation", 10)
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lvl_l := Label.new()
	lvl_l.name = "LevelLabel"
	lvl_l.text = tr("LABEL_LEVEL")
	lvl_l.add_theme_font_size_override("font_size", 17)
	toolbar.add_child(lvl_l)
	var lvl_opt := OptionButton.new()
	lvl_opt.name = "LevelOption"
	lvl_opt.custom_minimum_size = Vector2(118, 44)
	lvl_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in SudokuLevels.level_count():
		lvl_opt.add_item("%s %d" % [tr("LABEL_LEVEL"), i + 1], i)
	lvl_opt.select(_level_idx)
	lvl_opt.item_selected.connect(_on_level_selected)
	lvl_opt.add_theme_font_size_override("font_size", 17)
	toolbar.add_child(lvl_opt)
	var ng := Button.new()
	ng.name = "NewGameBtn"
	ng.text = tr("BTN_NEW_GAME")
	ng.custom_minimum_size = Vector2(0, 44)
	ng.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ng.pressed.connect(_new_game)
	ng.add_theme_font_size_override("font_size", 17)
	toolbar.add_child(ng)
	root_vb.add_child(toolbar)
	var row2 := HBoxContainer.new()
	row2.name = "Toolbar2"
	row2.add_theme_constant_override("separation", 10)
	row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var km := Button.new()
	km.name = "KeyModeBtn"
	km.toggle_mode = true
	km.text = _key_mode_button_label()
	km.custom_minimum_size = Vector2(0, 44)
	km.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	km.toggled.connect(_on_key_mode_toggled)
	km.add_theme_font_size_override("font_size", 16)
	row2.add_child(km)
	var unl := Button.new()
	unl.name = "UnlockBtn"
	unl.text = tr("BTN_UNLOCK")
	unl.custom_minimum_size = Vector2(0, 44)
	unl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unl.pressed.connect(_on_unlock)
	unl.add_theme_font_size_override("font_size", 16)
	row2.add_child(unl)
	root_vb.add_child(row2)
	var hint := Label.new()
	hint.name = "KeyHint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = tr("KEY_MODE_ON")
	hint.visible = false
	hint.add_theme_font_size_override("font_size", 15)
	root_vb.add_child(hint)
	var board_margin := MarginContainer.new()
	board_margin.name = "BoardMargin"
	board_margin.add_theme_constant_override("margin_left", BOARD_H_MARGIN)
	board_margin.add_theme_constant_override("margin_right", BOARD_H_MARGIN)
	board_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var board_slot := Control.new()
	board_slot.name = "BoardSlot"
	board_slot.clip_contents = false
	board_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var board_center := CenterContainer.new()
	board_center.name = "BoardCenter"
	board_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.name = "SudokuGrid"
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	_cell_buttons.clear()
	for i in CELL_COUNT:
		var b := Button.new()
		b.name = "C%d" % i
		b.custom_minimum_size = Vector2(MIN_CELL_PX, MIN_CELL_PX)
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		b.pressed.connect(_on_cell_pressed.bind(idx))
		grid.add_child(b)
		_cell_buttons.append(b)
	board_center.add_child(grid)
	board_slot.add_child(board_center)
	board_margin.add_child(board_slot)
	root_vb.add_child(board_margin)
	var pad_wrap := CenterContainer.new()
	pad_wrap.name = "NumPadWrap"
	pad_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := GridContainer.new()
	pad.name = "NumPad"
	pad.columns = 5
	pad.add_theme_constant_override("h_separation", 6)
	pad.add_theme_constant_override("v_separation", 6)
	for d in range(1, 10):
		var pb := Button.new()
		pb.text = str(d)
		pb.custom_minimum_size = Vector2(52, 44)
		pb.pressed.connect(_on_digit_pressed.bind(d))
		pad.add_child(pb)
	var clr := Button.new()
	clr.name = "ClearBtn"
	clr.text = tr("BTN_CLEAR_CELL")
	clr.custom_minimum_size = Vector2(52, 44)
	clr.pressed.connect(_on_clear_pressed)
	pad.add_child(clr)
	pad_wrap.add_child(pad)
	root_vb.add_child(pad_wrap)
	var margin_b := Control.new()
	margin_b.custom_minimum_size.y = safe_bottom
	root_vb.add_child(margin_b)
	_style_toolbar_and_pad()


func _apply_theme_background() -> void:
	var bg := get_node_or_null("ThemeBg") as ColorRect
	if bg == null:
		return
	var pal := ThemePalette.get_palette(GameSettings.theme_id)
	var blended: Color = (pal["bg_top"] as Color).lerp(pal["bg_bottom"] as Color, 0.45)
	bg.color = blended


func _fit_sudoku_grid() -> void:
	var slot := get_node_or_null("RootVB/BoardMargin/BoardSlot") as Control
	var grid := get_node_or_null("RootVB/BoardMargin/BoardSlot/BoardCenter/SudokuGrid") as GridContainer
	var root := get_node_or_null("RootVB") as Control
	if not slot or not grid or not root:
		return
	var sz := slot.size
	if sz.x < 16.0 or sz.y < 16.0:
		return
	var h_sep := float(grid.get_theme_constant("h_separation", "GridContainer"))
	var v_sep := float(grid.get_theme_constant("v_separation", "GridContainer"))
	if h_sep <= 0.0:
		h_sep = 2.0
	if v_sep <= 0.0:
		v_sep = 2.0
	var cw := (sz.x - 8.0 * h_sep) / 9.0
	var ch := (sz.y - 8.0 * v_sep) / 9.0
	var cell := int(floor(minf(cw, ch)))
	cell = clampi(cell, MIN_CELL_PX, 512)
	var fs := clampi(int(round(float(cell) * 0.42)), 16, 56)
	for b in _cell_buttons:
		b.custom_minimum_size = Vector2(cell, cell)
		b.add_theme_font_size_override("font_size", fs)
	var pad := root.get_node_or_null("NumPadWrap/NumPad") as GridContainer
	if pad:
		var full_w := maxf(root.size.x, 100.0)
		var pad_h := float(pad.get_theme_constant("h_separation", "GridContainer"))
		var pad_v := float(pad.get_theme_constant("v_separation", "GridContainer"))
		if pad_h <= 0.0:
			pad_h = 6.0
		if pad_v <= 0.0:
			pad_v = 6.0
		var ncol := 5
		var btn_w := (full_w - float(ncol - 1) * pad_h) / float(ncol)
		var btn_h := maxf(36.0, float(cell) * 0.5)
		btn_w = minf(btn_w, btn_h * 1.45)
		var pfs := clampi(int(round(btn_h * 0.38)), 14, 28)
		for ch_node in pad.get_children():
			if ch_node is Button:
				ch_node.custom_minimum_size = Vector2(int(btn_w), int(btn_h))
				ch_node.add_theme_font_size_override("font_size", pfs)


func _key_mode_button_label() -> String:
	var custom := GameSettings.key_mode_custom_title.strip_edges()
	return custom if not custom.is_empty() else tr("BTN_KEY_MODE")


func _style_toolbar_and_pad() -> void:
	var vb := get_node_or_null("RootVB") as VBoxContainer
	if not vb:
		return
	var pal := ThemePalette.get_palette(GameSettings.theme_id)
	for path in ["TopBar", "Toolbar", "Toolbar2"]:
		var row := vb.get_node_or_null(path) as HBoxContainer
		if row:
			for ch in row.get_children():
				if ch is Button or ch is OptionButton:
					var sb_btn := StyleBoxFlat.new()
					sb_btn.bg_color = pal["panel"]
					sb_btn.set_corner_radius_all(10)
					sb_btn.border_width_left = 1
					sb_btn.border_width_top = 1
					sb_btn.border_width_right = 1
					sb_btn.border_width_bottom = 1
					sb_btn.border_color = pal["panel_border"]
					ch.add_theme_stylebox_override("normal", sb_btn.duplicate())
					ch.add_theme_stylebox_override("hover", sb_btn.duplicate())
					ch.add_theme_stylebox_override("pressed", sb_btn.duplicate())
					UiFont.style_control_text(ch as Control, pal)
					if ch is OptionButton:
						UiFont.style_option_button(ch as OptionButton, pal, 17)
	var level_label := vb.get_node_or_null("Toolbar/LevelLabel") as Label
	if level_label:
		level_label.add_theme_color_override("font_color", pal["primary"])
	var hint := vb.get_node_or_null("KeyHint") as Label
	if hint:
		hint.add_theme_color_override("font_color", pal["muted"])
	var pad := vb.get_node_or_null("NumPadWrap/NumPad") as GridContainer
	if pad:
		for ch in pad.get_children():
			if ch is Button:
				var sbn := StyleBoxFlat.new()
				sbn.bg_color = pal["panel"]
				sbn.set_corner_radius_all(10)
				sbn.border_width_left = 1
				sbn.border_width_top = 1
				sbn.border_width_right = 1
				sbn.border_width_bottom = 1
				sbn.border_color = pal["panel_border"]
				ch.add_theme_stylebox_override("normal", sbn.duplicate())
				ch.add_theme_stylebox_override("hover", sbn.duplicate())
				ch.add_theme_stylebox_override("pressed", sbn.duplicate())
				UiFont.style_control_text(ch as Control, pal)
	var title := vb.get_node_or_null("TopBar/Title") as Label
	if title:
		title.add_theme_color_override("font_color", pal["primary"])


func _apply_all_texts() -> void:
	var vb := get_node_or_null("RootVB") as VBoxContainer
	if not vb:
		return
	var back := vb.get_node_or_null("TopBar/BackBtn") as Button
	if back:
		back.text = tr("BTN_BACK")
	var title := vb.get_node_or_null("TopBar/Title") as Label
	if title:
		title.text = tr("SUDOKU_TITLE")
	var lvl_l := vb.get_node_or_null("Toolbar/LevelLabel") as Label
	if lvl_l:
		lvl_l.text = tr("LABEL_LEVEL")
	var ng := vb.get_node_or_null("Toolbar/NewGameBtn") as Button
	if ng:
		ng.text = tr("BTN_NEW_GAME")
	var km := vb.get_node_or_null("Toolbar2/KeyModeBtn") as Button
	if km:
		km.text = _key_mode_button_label()
	var unl := vb.get_node_or_null("Toolbar2/UnlockBtn") as Button
	if unl:
		unl.text = tr("BTN_UNLOCK")
	var hint := vb.get_node_or_null("KeyHint") as Label
	if hint:
		hint.text = tr("KEY_MODE_ON")
	var clr := vb.get_node_or_null("NumPadWrap/NumPad/ClearBtn") as Button
	if clr:
		clr.text = tr("BTN_CLEAR_CELL")
	var loc := vb.get_node_or_null("TopBar/LocaleOption") as OptionButton
	if loc:
		var sel := loc.selected
		_fill_locale_option_items(loc)
		loc.select(clampi(sel, 0, loc.item_count - 1))
	_refresh_level_option_items()
	UiFont.bind_option_popups_in_tree(self, 17)


func _refresh_level_option_items() -> void:
	var opt := get_node_or_null("RootVB/Toolbar/LevelOption") as OptionButton
	if not opt:
		return
	var sel := opt.selected
	opt.clear()
	for i in SudokuLevels.level_count():
		opt.add_item("%s %d" % [tr("LABEL_LEVEL"), i + 1], i)
	opt.select(clampi(sel, 0, opt.item_count - 1))


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_level_selected(idx: int) -> void:
	_level_idx = idx
	_new_game()


func _on_key_mode_toggled(on: bool) -> void:
	_key_mode = on
	if on:
		_clear_custom_board()
		_show_toast(tr("TOAST_CUSTOM_READY"))
	var hint := get_node_or_null("RootVB/KeyHint") as Label
	if hint:
		hint.visible = on
	_refresh_all_cells()
	call_deferred("_fit_sudoku_grid")


func _clear_custom_board() -> void:
	for i in CELL_COUNT:
		_player[i] = 0
		_key_marks[i] = 0
		_key_digits[i] = 0
	_focused = -1


func _on_cell_pressed(idx: int) -> void:
	_focused = idx
	_refresh_cell(idx)


func _on_digit_pressed(d: int) -> void:
	if _focused < 0:
		return
	var i := _focused
	if _key_mode:
		_key_marks[i] = 1
		_key_digits[i] = d
		_player[i] = 0
	else:
		if _initial[i] != 0:
			return
		_player[i] = d
	_refresh_cell(i)


func _on_clear_pressed() -> void:
	if _focused < 0:
		return
	var i := _focused
	if _key_mode:
		_key_marks[i] = 0
		_key_digits[i] = 0
		_player[i] = 0
	else:
		if _initial[i] != 0:
			return
		_player[i] = 0
	_refresh_cell(i)


func _merged_for_solve() -> PackedInt32Array:
	var g := PackedInt32Array()
	g.resize(CELL_COUNT)
	for i in CELL_COUNT:
		if _key_mode:
			g[i] = _key_digits[i]
		elif _initial[i] != 0:
			g[i] = _initial[i]
		else:
			g[i] = _key_digits[i]
	return g


func _on_unlock() -> void:
	var merged := _merged_for_solve()
	if not SudokuSolver.validate_partial(merged):
		_show_toast(tr("ERR_CONFLICT"))
		return
	var res := SudokuSolver.solve(merged)
	if not res.get("ok", false):
		_show_toast("%s：%s" % [tr("DLG_NO_SOLUTION_TITLE"), tr("DLG_NO_SOLUTION_MSG")])
		return
	var sol: PackedInt32Array = res["solution"]
	for i in CELL_COUNT:
		if not _key_mode and _initial[i] != 0:
			continue
		if _key_marks[i] != 0 and _key_digits[i] != 0:
			continue
		_player[i] = sol[i]
	_refresh_all_cells()
	_show_toast(tr("TOAST_FILLED"))


func _show_toast(msg: String) -> void:
	var vb := get_node_or_null("RootVB") as VBoxContainer
	if not vb:
		print(msg)
		return
	var toast := Label.new()
	toast.name = "Toast"
	toast.text = msg
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_theme_color_override("font_color", ThemePalette.get_palette(GameSettings.theme_id)["primary"])
	toast.add_theme_font_size_override("font_size", 17)
	var pal := ThemePalette.get_palette(GameSettings.theme_id)
	var panel := StyleBoxFlat.new()
	panel.bg_color = pal["panel"]
	panel.set_corner_radius_all(12)
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = pal["panel_border"]
	panel.content_margin_left = 12
	panel.content_margin_top = 8
	panel.content_margin_right = 12
	panel.content_margin_bottom = 8
	toast.add_theme_stylebox_override("normal", panel)
	UiFont.bind_control(toast)
	vb.add_child(toast)
	vb.move_child(toast, vb.get_child_count() - 2)
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(toast):
		toast.queue_free()


func _new_game() -> void:
	var p := SudokuGenerator.generate_for_level(_level_idx, _rng)
	if p.is_empty():
		push_error("生成题目失败，请重试")
		return
	_initial = p
	_player = p.duplicate()
	_key_marks.resize(CELL_COUNT)
	_key_digits.resize(CELL_COUNT)
	for i in CELL_COUNT:
		_key_marks[i] = 0
		_key_digits[i] = 0
	_focused = -1
	_key_mode = false
	var km := get_node_or_null("RootVB/Toolbar2/KeyModeBtn") as Button
	if km:
		km.button_pressed = false
	var hint := get_node_or_null("RootVB/KeyHint") as Label
	if hint:
		hint.visible = false
	_refresh_all_cells()
	call_deferred("_fit_sudoku_grid")


func _display_digit(idx: int) -> int:
	if _key_mode:
		if _key_digits[idx] != 0:
			return _key_digits[idx]
		return _player[idx]
	if _initial[idx] != 0:
		return _initial[idx]
	if _key_marks[idx] != 0 and _key_digits[idx] != 0:
		return _key_digits[idx]
	return _player[idx]


func _refresh_cell(idx: int) -> void:
	var b := _cell_buttons[idx]
	var v := _display_digit(idx)
	b.text = "" if v == 0 else str(v)
	var pal := ThemePalette.get_palette(GameSettings.theme_id)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	var r := idx / 9
	var c := idx % 9
	sb.border_width_top = 3 if r % 3 == 0 else 1
	sb.border_width_left = 3 if c % 3 == 0 else 1
	sb.border_width_bottom = 3 if r == 8 or r % 3 == 2 else 1
	sb.border_width_right = 3 if c == 8 or c % 3 == 2 else 1
	if not _key_mode and _initial[idx] != 0:
		sb.bg_color = pal["fixed"]
		sb.border_color = pal["grid_line"]
	elif _key_marks[idx] != 0 and _key_digits[idx] != 0:
		sb.bg_color = pal["cell"]
		sb.border_color = pal["key_border"]
	else:
		var alt := (idx / 9 + idx % 9) % 2 == 0
		sb.bg_color = pal["cell"] if alt else pal["cell_alt"]
		sb.border_color = pal["grid_line"]
	b.add_theme_stylebox_override("normal", sb.duplicate())
	b.add_theme_stylebox_override("hover", sb.duplicate())
	b.add_theme_stylebox_override("pressed", sb.duplicate())
	UiFont.style_control_text(b, pal)


func _refresh_all_cells() -> void:
	for i in CELL_COUNT:
		_refresh_cell(i)

