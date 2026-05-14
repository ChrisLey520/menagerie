extends Control
## 消消乐：顶栏、棋盘、分数步数、提示与胜负层

const BOARD_H_MARGIN := 16
const GAP_PX := 4
const CELL_PX_MIN := 52
const CELL_PX_MAX := 88
const SWAP_OK_SEC := 0.18
const SWAP_FAIL_SEC := 0.12
const GEM_CORNER_MIN := 8
const GEM_CORNER_MAX := 14

var _rng := RandomNumberGenerator.new()
var _model: Match3BoardModel
var _pal: Dictionary = {}

var _busy: bool = false
var _selected_idx: int = -1

var _cell_outer: Array[Panel] = []
var _gem_inner: Array[Panel] = []
var _hint_pair: Vector2i = Vector2i(-1, -1)
var _hint_tweens: Array[Tween] = []


func _ready() -> void:
	_rng.randomize()
	_model = Match3BoardModel.new(_rng)
	_pal = ThemePalette.get_palette(GameSettings.theme_id)
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
	call_deferred("_fit_board_grid")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_fit_board_grid")


func _on_viewport_resized() -> void:
	call_deferred("_fit_board_grid")


func _on_theme_changed(_id: String) -> void:
	_pal = ThemePalette.get_palette(GameSettings.theme_id)
	_apply_theme_background()
	_style_chrome()
	_sync_all_cells_visual()
	_style_selection()


func _on_locale_changed(_code: String) -> void:
	_apply_all_texts()
	var loc := get_node_or_null("RootVB/TopBar/LocaleOption") as OptionButton
	if loc:
		var idx := GameSettings.locale_display_index(GameSettings.locale_code)
		if idx >= 0:
			loc.select(idx)


func _apply_theme_background() -> void:
	var bg := get_node_or_null("ThemeBg") as ColorRect
	if bg == null:
		return
	var blended: Color = (_pal["bg_top"] as Color).lerp(_pal["bg_bottom"] as Color, 0.45)
	bg.color = blended


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
	root_vb.add_theme_constant_override("separation", 14)
	add_child(root_vb)
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.add_theme_constant_override("separation", 10)
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := Button.new()
	back.name = "BackBtn"
	back.text = tr("BTN_BACK")
	back.custom_minimum_size = Vector2(78, 46)
	back.pressed.connect(_on_back)
	back.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(back)
	var title := Label.new()
	title.name = "Title"
	title.text = tr("MATCH3_TITLE")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	top_bar.add_child(title)
	var loc := OptionButton.new()
	loc.name = "LocaleOption"
	loc.custom_minimum_size = Vector2(138, 46)
	loc.size_flags_horizontal = Control.SIZE_SHRINK_END
	_fill_locale_option_items(loc)
	var li := GameSettings.locale_display_index(GameSettings.locale_code)
	loc.select(li if li >= 0 else 0)
	loc.item_selected.connect(_on_locale_picked)
	loc.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(loc)
	root_vb.add_child(top_bar)
	var stat_row := HBoxContainer.new()
	stat_row.name = "StatRow"
	stat_row.add_theme_constant_override("separation", 10)
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var score_box := VBoxContainer.new()
	score_box.name = "ScoreBox"
	score_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var score_l := Label.new()
	score_l.name = "ScoreCaption"
	score_l.text = tr("MATCH3_LABEL_SCORE")
	score_l.add_theme_font_size_override("font_size", 17)
	score_box.add_child(score_l)
	var score_v := Label.new()
	score_v.name = "ScoreValue"
	score_v.text = "0"
	score_v.add_theme_font_size_override("font_size", 32)
	score_box.add_child(score_v)
	stat_row.add_child(score_box)
	var moves_box := VBoxContainer.new()
	moves_box.name = "MovesBox"
	moves_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var moves_l := Label.new()
	moves_l.name = "MovesCaption"
	moves_l.text = tr("MATCH3_LABEL_MOVES")
	moves_l.add_theme_font_size_override("font_size", 17)
	moves_box.add_child(moves_l)
	var moves_v := Label.new()
	moves_v.name = "MovesValue"
	moves_v.text = str(Match3BoardModel.MOVES_START)
	moves_v.add_theme_font_size_override("font_size", 32)
	moves_box.add_child(moves_v)
	stat_row.add_child(moves_box)
	var hint_btn := Button.new()
	hint_btn.name = "HintBtn"
	hint_btn.text = tr("MATCH3_HINT_BTN")
	hint_btn.custom_minimum_size = Vector2(0, 46)
	hint_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_btn.pressed.connect(_on_hint_pressed)
	hint_btn.add_theme_font_size_override("font_size", 16)
	stat_row.add_child(hint_btn)
	var ng := Button.new()
	ng.name = "NewGameBtn"
	ng.text = tr("BTN_NEW_GAME")
	ng.custom_minimum_size = Vector2(0, 46)
	ng.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ng.pressed.connect(_new_game)
	ng.add_theme_font_size_override("font_size", 16)
	stat_row.add_child(ng)
	root_vb.add_child(stat_row)
	var hint_line := Label.new()
	hint_line.name = "HintLine"
	hint_line.text = tr("MATCH3_HINT_LINE")
	hint_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_line.add_theme_font_size_override("font_size", 15)
	root_vb.add_child(hint_line)
	var board_margin := MarginContainer.new()
	board_margin.name = "BoardMargin"
	board_margin.add_theme_constant_override("margin_left", BOARD_H_MARGIN)
	board_margin.add_theme_constant_override("margin_right", BOARD_H_MARGIN)
	board_margin.add_theme_constant_override("margin_top", 12)
	board_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var board_slot := Control.new()
	board_slot.name = "BoardSlot"
	board_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var board_center := CenterContainer.new()
	board_center.name = "BoardCenter"
	board_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.name = "MatchGrid"
	grid.columns = Match3BoardModel.COLS
	grid.add_theme_constant_override("h_separation", GAP_PX)
	grid.add_theme_constant_override("v_separation", GAP_PX)
	_cell_outer.clear()
	_gem_inner.clear()
	for i in Match3BoardModel.ROWS * Match3BoardModel.COLS:
		var outer := Panel.new()
		outer.name = "C%d" % i
		outer.mouse_filter = Control.MOUSE_FILTER_STOP
		outer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		outer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var inner := Panel.new()
		inner.name = "Gem"
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		outer.add_child(inner)
		var idx := i
		outer.gui_input.connect(_on_cell_gui.bind(idx))
		grid.add_child(outer)
		_cell_outer.append(outer)
		_gem_inner.append(inner)
	board_center.add_child(grid)
	board_slot.add_child(board_center)
	board_margin.add_child(board_slot)
	root_vb.add_child(board_margin)
	var margin_b := Control.new()
	margin_b.custom_minimum_size.y = 28
	root_vb.add_child(margin_b)
	_build_overlay()
	_style_chrome()


func _build_overlay() -> void:
	var ov := Control.new()
	ov.name = "EndOverlay"
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.visible = false
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.add_child(dim)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var card := PanelContainer.new()
	card.name = "Card"
	card.custom_minimum_size = Vector2(280, 200)
	center.add_child(card)
	var vb := VBoxContainer.new()
	vb.name = "VBox"
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)
	var title := Label.new()
	title.name = "EndTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)
	var body := Label.new()
	body.name = "EndBody"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 17)
	vb.add_child(body)
	var row := HBoxContainer.new()
	row.name = "BtnRow"
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var again := Button.new()
	again.name = "AgainBtn"
	again.text = tr("MATCH3_BTN_AGAIN")
	again.custom_minimum_size = Vector2(120, 48)
	again.pressed.connect(_on_overlay_again)
	again.add_theme_font_size_override("font_size", 17)
	row.add_child(again)
	var menu := Button.new()
	menu.name = "MenuBtn"
	menu.text = tr("MATCH3_BTN_MENU")
	menu.custom_minimum_size = Vector2(120, 48)
	menu.pressed.connect(_on_overlay_menu)
	menu.add_theme_font_size_override("font_size", 17)
	row.add_child(menu)
	vb.add_child(row)
	add_child(ov)


func _fill_locale_option_items(opt: OptionButton) -> void:
	opt.clear()
	opt.add_item(tr("LANG_ZH_CN"))
	opt.add_item(tr("LANG_ZH_TW"))
	opt.add_item(tr("LANG_EN"))


func _on_locale_picked(idx: int) -> void:
	if idx >= 0 and idx < GameSettings.LOCALE_IDS.size():
		GameSettings.locale_code = GameSettings.LOCALE_IDS[idx]


func _style_chrome() -> void:
	var vb := get_node_or_null("RootVB") as VBoxContainer
	if vb == null:
		return
	UiChrome.style_sudoku_toolbars(vb, _pal)
	var hint_btn := vb.get_node_or_null("StatRow/HintBtn") as Button
	if hint_btn:
		UiChrome.style_secondary_control(hint_btn, _pal)
	var ng := vb.get_node_or_null("StatRow/NewGameBtn") as Button
	if ng:
		UiChrome.style_secondary_control(ng, _pal)
	var back := vb.get_node_or_null("TopBar/BackBtn") as Button
	if back:
		UiChrome.style_secondary_control(back, _pal)
	var loc := vb.get_node_or_null("TopBar/LocaleOption") as OptionButton
	if loc:
		UiChrome.style_secondary_control(loc, _pal)
		UiFont.style_option_button(loc, _pal, 17)
	var title := vb.get_node_or_null("TopBar/Title") as Label
	if title:
		title.add_theme_color_override("font_color", _pal["primary"])
	var hl := vb.get_node_or_null("HintLine") as Label
	if hl:
		hl.add_theme_color_override("font_color", _pal["muted"])
	var score_cap := vb.get_node_or_null("StatRow/ScoreBox/ScoreCaption") as Label
	if score_cap:
		score_cap.add_theme_color_override("font_color", _pal["muted"])
	var moves_cap := vb.get_node_or_null("StatRow/MovesBox/MovesCaption") as Label
	if moves_cap:
		moves_cap.add_theme_color_override("font_color", _pal["muted"])
	var sv := vb.get_node_or_null("StatRow/ScoreBox/ScoreValue") as Label
	if sv:
		sv.add_theme_color_override("font_color", _pal["primary"])
	var mv := vb.get_node_or_null("StatRow/MovesBox/MovesValue") as Label
	if mv:
		mv.add_theme_color_override("font_color", _pal["primary"])


func _apply_all_texts() -> void:
	var vb := get_node_or_null("RootVB") as VBoxContainer
	if vb == null:
		return
	var back := vb.get_node_or_null("TopBar/BackBtn") as Button
	if back:
		back.text = tr("BTN_BACK")
	var title := vb.get_node_or_null("TopBar/Title") as Label
	if title:
		title.text = tr("MATCH3_TITLE")
	var hint_btn := vb.get_node_or_null("StatRow/HintBtn") as Button
	if hint_btn:
		hint_btn.text = tr("MATCH3_HINT_BTN")
	var ng := vb.get_node_or_null("StatRow/NewGameBtn") as Button
	if ng:
		ng.text = tr("BTN_NEW_GAME")
	var hl := vb.get_node_or_null("HintLine") as Label
	if hl:
		hl.text = tr("MATCH3_HINT_LINE")
	var sc := vb.get_node_or_null("StatRow/ScoreBox/ScoreCaption") as Label
	if sc:
		sc.text = tr("MATCH3_LABEL_SCORE")
	var mc := vb.get_node_or_null("StatRow/MovesBox/MovesCaption") as Label
	if mc:
		mc.text = tr("MATCH3_LABEL_MOVES")
	var loc := vb.get_node_or_null("TopBar/LocaleOption") as OptionButton
	if loc:
		var sel := loc.selected
		_fill_locale_option_items(loc)
		loc.select(clampi(sel, 0, loc.item_count - 1))
	UiFont.bind_option_popups_in_tree(self, 17)
	_style_chrome()


func _fit_board_grid() -> void:
	var slot := get_node_or_null("RootVB/BoardMargin/BoardSlot") as Control
	var grid := get_node_or_null("RootVB/BoardMargin/BoardSlot/BoardCenter/MatchGrid") as GridContainer
	if slot == null or grid == null:
		return
	var sz := slot.size
	if sz.x < 32.0 or sz.y < 32.0:
		return
	var cols := Match3BoardModel.COLS
	var rows := Match3BoardModel.ROWS
	var h_sep := float(GAP_PX)
	var v_sep := float(GAP_PX)
	var cw := (sz.x - float(cols - 1) * h_sep) / float(cols)
	var ch := (sz.y - float(rows - 1) * v_sep) / float(rows)
	var cell := int(floor(minf(cw, ch)))
	cell = clampi(cell, CELL_PX_MIN, CELL_PX_MAX)
	var corner := clampi(cell / 5, GEM_CORNER_MIN, GEM_CORNER_MAX)
	var inset := maxi(4, int(round(float(cell) * 0.08)))
	for i in _cell_outer.size():
		var outer := _cell_outer[i]
		var inner := _gem_inner[i]
		outer.custom_minimum_size = Vector2(cell, cell)
		inner.offset_left = inset
		inner.offset_top = inset
		inner.offset_right = -inset
		inner.offset_bottom = -inset
		_style_slot_panel(outer, corner)
		var t: int = _model.cells[i] if i < _model.cells.size() else 0
		_style_gem_panel(inner, t, corner, false)
	_style_selection()


func _style_slot_panel(p: Panel, _corner_unused: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _pal["panel"] as Color
	sb.set_corner_radius_all(10)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = _pal["grid_line"] as Color
	p.add_theme_stylebox_override("panel", sb)


func _style_gem_panel(
	p: Panel, gem_type: int, corner: int, hint_glow: bool, selected: bool = false
) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Match3GemPalette.fill_for_type(gem_type)
	sb.set_corner_radius_all(corner)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Match3GemPalette.border_for_type(gem_type)
	if hint_glow:
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = _pal["accent"] as Color
		sb.shadow_color = (_pal["accent"] as Color)
		sb.shadow_color.a = 0.35
		sb.shadow_size = 8
		sb.shadow_offset = Vector2i(0, 2)
	elif selected:
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = _pal["key_border"] as Color
	p.add_theme_stylebox_override("panel", sb)


func _sync_all_cells_visual() -> void:
	var grid := get_node_or_null("RootVB/BoardMargin/BoardSlot/BoardCenter/MatchGrid") as GridContainer
	if grid == null:
		return
	var cell := 52
	if _cell_outer.size() > 0 and _cell_outer[0].custom_minimum_size.x > 0:
		cell = int(_cell_outer[0].custom_minimum_size.x)
	var corner := clampi(cell / 5, GEM_CORNER_MIN, GEM_CORNER_MAX)
	for i in _gem_inner.size():
		if i >= _model.cells.size():
			break
		var t: int = _model.cells[i]
		var hint_on := (i == _hint_pair.x or i == _hint_pair.y)
		var sel := (i == _selected_idx)
		_style_gem_panel(_gem_inner[i], t, corner, hint_on, sel)


func _style_selection() -> void:
	if _cell_outer.is_empty():
		return
	var cell := int(_cell_outer[0].custom_minimum_size.x) if _cell_outer[0].custom_minimum_size.x > 0 else 52
	var corner := clampi(cell / 5, GEM_CORNER_MIN, GEM_CORNER_MAX)
	for i in _gem_inner.size():
		if i >= _model.cells.size():
			break
		var t: int = _model.cells[i]
		var hint_on := (i == _hint_pair.x or i == _hint_pair.y)
		var sel := (i == _selected_idx)
		_style_gem_panel(_gem_inner[i], t, corner, hint_on, sel)


func _on_cell_gui(event: InputEvent, idx: int) -> void:
	if _busy or _model.is_won() or _model.is_lost():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pick(idx)


func _handle_pick(idx: int) -> void:
	_clear_hint_visual()
	if _selected_idx < 0:
		_selected_idx = idx
		_style_selection()
		return
	if _selected_idx == idx:
		_selected_idx = -1
		_style_selection()
		return
	if not _model.are_adjacent(_selected_idx, idx):
		_selected_idx = idx
		_style_selection()
		return
	var a := _selected_idx
	var b := idx
	_selected_idx = -1
	_style_selection()
	_try_swap_cells(a, b)


func _clear_hint_visual() -> void:
	_stop_hint_pulse()
	_hint_pair = Vector2i(-1, -1)


func _try_swap_cells(a: int, b: int) -> void:
	if not _model.are_adjacent(a, b):
		return
	_busy = true
	if not _model.swap_creates_match(a, b):
		await _tween_swap_visual_fail(a, b)
		_busy = false
		return
	await _tween_swap_visual_ok(a, b)
	_model.try_player_swap(a, b)
	_refresh_stats()
	_sync_all_cells_visual()
	_check_end_state()
	_busy = false


func _tween_swap_visual_ok(a: int, b: int) -> void:
	var ga := _gem_inner[a] as Control
	var gb := _gem_inner[b] as Control
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ga, "scale", Vector2(1.08, 1.08), SWAP_OK_SEC * 0.5).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	tw.tween_property(gb, "scale", Vector2(1.08, 1.08), SWAP_OK_SEC * 0.5).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	await tw.finished
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(ga, "scale", Vector2.ONE, SWAP_OK_SEC * 0.5).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	tw2.tween_property(gb, "scale", Vector2.ONE, SWAP_OK_SEC * 0.5).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	await tw2.finished


func _tween_swap_visual_fail(a: int, b: int) -> void:
	var ga := _gem_inner[a] as Control
	var gb := _gem_inner[b] as Control
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ga, "scale", Vector2(0.92, 0.92), SWAP_FAIL_SEC * 0.5).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(gb, "scale", Vector2(0.92, 0.92), SWAP_FAIL_SEC * 0.5).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(ga, "scale", Vector2.ONE, SWAP_FAIL_SEC * 0.5).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN_OUT)
	tw2.tween_property(gb, "scale", Vector2.ONE, SWAP_FAIL_SEC * 0.5).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN_OUT)
	await tw2.finished


func _refresh_stats() -> void:
	var vb := get_node_or_null("RootVB") as VBoxContainer
	if vb == null:
		return
	var sv := vb.get_node_or_null("StatRow/ScoreBox/ScoreValue") as Label
	if sv:
		sv.text = str(_model.score)
	var mv := vb.get_node_or_null("StatRow/MovesBox/MovesValue") as Label
	if mv:
		mv.text = str(_model.moves_left)


func _new_game() -> void:
	_clear_hint_visual()
	_selected_idx = -1
	_model.new_game()
	_refresh_stats()
	_sync_all_cells_visual()
	var ov := get_node_or_null("EndOverlay") as Control
	if ov:
		ov.visible = false


func _check_end_state() -> void:
	if _model.is_won():
		_show_end_overlay(true)
	elif _model.is_lost():
		_show_end_overlay(false)


func _show_end_overlay(won: bool) -> void:
	var ov := get_node_or_null("EndOverlay") as Control
	if ov == null:
		return
	ov.visible = true
	var title := ov.get_node_or_null("Center/Card/VBox/EndTitle") as Label
	var body := ov.get_node_or_null("Center/Card/VBox/EndBody") as Label
	var card := ov.get_node_or_null("Center/Card") as PanelContainer
	if won:
		if title:
			title.text = tr("MATCH3_WIN_TITLE")
			title.add_theme_color_override("font_color", _pal["accent"] as Color)
		if body:
			body.text = tr("MATCH3_WIN_BODY")
			body.add_theme_color_override("font_color", _pal["primary"] as Color)
	else:
		if title:
			title.text = tr("MATCH3_LOSE_TITLE")
			title.add_theme_color_override("font_color", _pal["accent"] as Color)
		if body:
			body.text = tr("MATCH3_LOSE_BODY")
			body.add_theme_color_override("font_color", _pal["primary"] as Color)
	if card:
		UiChrome.style_card_panel(card, _pal)
	var again := ov.get_node_or_null("Center/Card/VBox/BtnRow/AgainBtn") as Button
	var menu := ov.get_node_or_null("Center/Card/VBox/BtnRow/MenuBtn") as Button
	if again:
		UiChrome.style_primary_button(again, _pal)
		again.text = tr("MATCH3_BTN_AGAIN")
	if menu:
		UiChrome.style_secondary_control(menu, _pal)
		menu.text = tr("MATCH3_BTN_MENU")
	UiFont.bind_tree(ov)


func _on_overlay_again() -> void:
	var ov := get_node_or_null("EndOverlay") as Control
	if ov:
		ov.visible = false
	_new_game()


func _on_overlay_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_hint_pressed() -> void:
	if _busy:
		return
	if _model.is_won() or _model.is_lost():
		return
	var p := _model.try_use_hint()
	if p.x < 0:
		_show_toast(tr("MATCH3_TOAST_NO_HINT"))
		return
	_hint_pair = p
	_sync_all_cells_visual()
	_show_toast(tr("MATCH3_TOAST_HINT"))
	_start_hint_pulse()


func _start_hint_pulse() -> void:
	_stop_hint_pulse()
	if _hint_pair.x < 0:
		return
	var ga := _gem_inner[_hint_pair.x]
	var gb := _gem_inner[_hint_pair.y]
	var tw1 := create_tween()
	tw1.set_loops()
	tw1.tween_property(ga, "modulate:a", 0.72, 0.45)
	tw1.tween_property(ga, "modulate:a", 1.0, 0.45)
	_hint_tweens.append(tw1)
	var tw2 := create_tween()
	tw2.set_loops()
	tw2.tween_property(gb, "modulate:a", 0.72, 0.45)
	tw2.tween_property(gb, "modulate:a", 1.0, 0.45)
	_hint_tweens.append(tw2)


func _stop_hint_pulse() -> void:
	for tw in _hint_tweens:
		if tw != null:
			tw.kill()
	_hint_tweens.clear()
	for g in _gem_inner:
		g.modulate = Color(1, 1, 1, 1)


func _show_toast(msg: String) -> void:
	var vb := get_node_or_null("RootVB") as VBoxContainer
	if vb == null:
		print(msg)
		return
	var toast := Label.new()
	toast.name = "Toast"
	toast.text = msg
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_theme_font_size_override("font_size", 17)
	UiChrome.style_toast_label(toast, _pal)
	UiFont.bind_control(toast)
	vb.add_child(toast)
	vb.move_child(toast, vb.get_child_count() - 2)
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(toast):
		toast.queue_free()
