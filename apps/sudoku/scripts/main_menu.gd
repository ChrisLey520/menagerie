extends Control
## 合集首页：进入数独、语言 / 主题

func _ready() -> void:
	_build_ui()
	GameSettings.theme_changed.connect(_on_theme_changed)
	GameSettings.locale_changed.connect(_on_locale_changed)
	_apply_theme()


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", maxi(24, int(get_viewport().get_visible_rect().size.y * 0.02)))
	scroll.add_child(margin)
	var vb := VBoxContainer.new()
	vb.name = "MainVBox"
	vb.add_theme_constant_override("separation", 16)
	margin.add_child(vb)
	var title := Label.new()
	title.name = "Title"
	title.text = tr("APP_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vb.add_child(title)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = tr("MENU_SUBTITLE")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(sub)
	var play := Button.new()
	play.name = "PlaySudoku"
	play.text = tr("BTN_PLAY_SUDOKU")
	play.custom_minimum_size = Vector2(0, 52)
	play.pressed.connect(_on_play_sudoku)
	vb.add_child(play)
	var lang_row := HBoxContainer.new()
	lang_row.name = "LangRow"
	lang_row.add_theme_constant_override("separation", 12)
	var lang_l := Label.new()
	lang_l.name = "LangLabel"
	lang_l.text = tr("LABEL_LANGUAGE")
	lang_l.custom_minimum_size.x = 96
	lang_row.add_child(lang_l)
	var lang_opt := OptionButton.new()
	lang_opt.name = "LocaleOption"
	lang_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fill_locale_option(lang_opt)
	var cur_i := GameSettings.locale_display_index(GameSettings.locale_code)
	lang_opt.select(cur_i if cur_i >= 0 else 0)
	lang_opt.item_selected.connect(_on_locale_selected)
	lang_row.add_child(lang_opt)
	vb.add_child(lang_row)
	var theme_row := HBoxContainer.new()
	theme_row.name = "ThemeRow"
	theme_row.add_theme_constant_override("separation", 12)
	var theme_l := Label.new()
	theme_l.name = "ThemeLabel"
	theme_l.text = tr("LABEL_THEME")
	theme_l.custom_minimum_size.x = 96
	theme_row.add_child(theme_l)
	var theme_opt := OptionButton.new()
	theme_opt.name = "ThemeOption"
	theme_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fill_theme_option(theme_opt)
	var ti := GameSettings.theme_display_index(GameSettings.theme_id)
	theme_opt.select(ti if ti >= 0 else 0)
	theme_opt.item_selected.connect(_on_theme_selected)
	theme_row.add_child(theme_opt)
	vb.add_child(theme_row)


func _fill_locale_option(opt: OptionButton) -> void:
	opt.clear()
	opt.add_item(tr("LANG_ZH_CN"))
	opt.add_item(tr("LANG_ZH_TW"))
	opt.add_item(tr("LANG_EN"))


func _fill_theme_option(opt: OptionButton) -> void:
	opt.clear()
	opt.add_item(tr("THEME_FOREST"))
	opt.add_item(tr("THEME_OCEAN"))
	opt.add_item(tr("THEME_DAWN"))
	opt.add_item(tr("THEME_DUSK"))


func _on_play_sudoku() -> void:
	get_tree().change_scene_to_file("res://scenes/sudoku_game.tscn")


func _on_locale_selected(idx: int) -> void:
	if idx >= 0 and idx < GameSettings.LOCALE_IDS.size():
		GameSettings.locale_code = GameSettings.LOCALE_IDS[idx]


func _on_theme_selected(idx: int) -> void:
	if idx >= 0 and idx < GameSettings.THEME_IDS.size():
		GameSettings.theme_id = GameSettings.THEME_IDS[idx]
	_apply_theme()


func _on_theme_changed(_id: String) -> void:
	_apply_theme()


func _on_locale_changed(_code: String) -> void:
	_rebuild_texts()


func _rebuild_texts() -> void:
	var vb := get_node_or_null("Scroll/Margin/MainVBox") as VBoxContainer
	if not vb:
		return
	var title := vb.get_node_or_null("Title") as Label
	if title:
		title.text = tr("APP_TITLE")
	var sub := vb.get_node_or_null("Subtitle") as Label
	if sub:
		sub.text = tr("MENU_SUBTITLE")
	var play := vb.get_node_or_null("PlaySudoku") as Button
	if play:
		play.text = tr("BTN_PLAY_SUDOKU")
	var lang_l := vb.get_node_or_null("LangLabel") as Label
	if lang_l:
		lang_l.text = tr("LABEL_LANGUAGE")
	var theme_l := vb.get_node_or_null("ThemeLabel") as Label
	if theme_l:
		theme_l.text = tr("LABEL_THEME")
	var lo := vb.get_node_or_null("LangRow/LocaleOption") as OptionButton
	if lo:
		var sel := lo.selected
		_fill_locale_option(lo)
		lo.select(clampi(sel, 0, lo.item_count - 1))
	var to := vb.get_node_or_null("ThemeRow/ThemeOption") as OptionButton
	if to:
		var sel2 := to.selected
		_fill_theme_option(to)
		to.select(clampi(sel2, 0, to.item_count - 1))


func _apply_theme() -> void:
	var pal := ThemePalette.get_palette(GameSettings.theme_id)
	var blended := pal["bg_top"].lerp(pal["bg_bottom"], 0.45)
	var sb := StyleBoxFlat.new()
	sb.bg_color = blended
	sb.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", sb)

	var vb := get_node_or_null("Scroll/Margin/MainVBox") as VBoxContainer
	if vb:
		var title := vb.get_node_or_null("Title") as Label
		if title:
			title.add_theme_color_override("font_color", pal["primary"])
		var sub := vb.get_node_or_null("Subtitle") as Label
		if sub:
			sub.add_theme_color_override("font_color", pal["muted"])
