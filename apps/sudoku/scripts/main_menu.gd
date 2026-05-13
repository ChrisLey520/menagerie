extends Control
## 合集首页：进入数独、语言 / 主题

func _ready() -> void:
	# 须在 GameSettings._deferred_sync_locale 之后首次构建，否则 Web 上首帧 tr() 仍落在浏览器语言（常为英文）
	GameSettings.theme_changed.connect(_on_theme_changed)
	GameSettings.locale_changed.connect(_on_locale_changed)
	call_deferred("_boot_initial_ui")


func _boot_initial_ui() -> void:
	_build_ui()
	UiFont.bind_tree(self)
	UiFont.bind_option_popups_in_tree(self, 17)
	_apply_theme()


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()
	var theme_bg := ColorRect.new()
	theme_bg.name = "ThemeBg"
	theme_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	theme_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(theme_bg)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	var scroll_panel_empty := StyleBoxEmpty.new()
	scroll.add_theme_stylebox_override("panel", scroll_panel_empty)
	add_child(scroll)
	var center := CenterContainer.new()
	center.name = "ContentCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", maxi(24, int(get_viewport().get_visible_rect().size.y * 0.02)))
	center.add_child(margin)
	var vb := VBoxContainer.new()
	vb.name = "MainVBox"
	vb.add_theme_constant_override("separation", 16)
	var vw := int(get_viewport().get_visible_rect().size.x)
	vb.custom_minimum_size.x = clampi(vw - 40, 280, 520)
	margin.add_child(vb)
	var title := Label.new()
	title.name = "Title"
	title.text = tr("APP_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vb.add_child(title)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = tr("MENU_SUBTITLE")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 18)
	vb.add_child(sub)
	var play := Button.new()
	play.name = "PlaySudoku"
	play.text = tr("BTN_PLAY_SUDOKU")
	play.custom_minimum_size = Vector2(0, 54)
	play.add_theme_font_size_override("font_size", 18)
	play.pressed.connect(_on_play_sudoku)
	vb.add_child(play)
	var lang_row := HBoxContainer.new()
	lang_row.name = "LangRow"
	lang_row.add_theme_constant_override("separation", 12)
	var lang_l := Label.new()
	lang_l.name = "LangLabel"
	lang_l.text = tr("LABEL_LANGUAGE")
	lang_l.custom_minimum_size.x = 104
	lang_l.add_theme_font_size_override("font_size", 17)
	lang_row.add_child(lang_l)
	var lang_opt := OptionButton.new()
	lang_opt.name = "LocaleOption"
	lang_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fill_locale_option(lang_opt)
	var cur_i := GameSettings.locale_display_index(GameSettings.locale_code)
	lang_opt.select(cur_i if cur_i >= 0 else 0)
	lang_opt.item_selected.connect(_on_locale_selected)
	lang_opt.add_theme_font_size_override("font_size", 17)
	lang_opt.custom_minimum_size.x = 148
	lang_row.add_child(lang_opt)
	vb.add_child(lang_row)
	var theme_row := HBoxContainer.new()
	theme_row.name = "ThemeRow"
	theme_row.add_theme_constant_override("separation", 12)
	var theme_l := Label.new()
	theme_l.name = "ThemeLabel"
	theme_l.text = tr("LABEL_THEME")
	theme_l.custom_minimum_size.x = 104
	theme_l.add_theme_font_size_override("font_size", 17)
	theme_row.add_child(theme_l)
	var theme_opt := OptionButton.new()
	theme_opt.name = "ThemeOption"
	theme_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fill_theme_option(theme_opt)
	var ti := GameSettings.theme_display_index(GameSettings.theme_id)
	theme_opt.select(ti if ti >= 0 else 0)
	theme_opt.item_selected.connect(_on_theme_selected)
	theme_opt.add_theme_font_size_override("font_size", 17)
	theme_opt.custom_minimum_size.x = 148
	theme_row.add_child(theme_opt)
	vb.add_child(theme_row)
	var km_row := HBoxContainer.new()
	km_row.name = "KeyModeRow"
	km_row.add_theme_constant_override("separation", 12)
	var km_l := Label.new()
	km_l.name = "KeyModeLabel"
	km_l.text = tr("LABEL_KEY_MODE_NAME")
	km_l.custom_minimum_size.x = 104
	km_l.add_theme_font_size_override("font_size", 17)
	km_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	km_row.add_child(km_l)
	var km_edit := LineEdit.new()
	km_edit.name = "KeyModeTitleEdit"
	km_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	km_edit.placeholder_text = tr("PLACEHOLDER_KEY_MODE_CUSTOM")
	km_edit.text = GameSettings.key_mode_custom_title
	km_edit.focus_exited.connect(_on_key_mode_title_focus_out.bind(km_edit))
	km_edit.text_submitted.connect(_on_key_mode_title_submitted)
	km_edit.add_theme_font_size_override("font_size", 17)
	km_row.add_child(km_edit)
	vb.add_child(km_row)


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


func _on_key_mode_title_focus_out(edit: LineEdit) -> void:
	GameSettings.key_mode_custom_title = edit.text.strip_edges()


func _on_key_mode_title_submitted(new_text: String) -> void:
	GameSettings.key_mode_custom_title = new_text.strip_edges()
	var edit := get_node_or_null("Scroll/ContentCenter/Margin/MainVBox/KeyModeRow/KeyModeTitleEdit") as LineEdit
	if edit:
		edit.release_focus()


func _on_theme_changed(_id: String) -> void:
	_apply_theme()


func _on_locale_changed(_code: String) -> void:
	_rebuild_texts()


func _rebuild_texts() -> void:
	var vb := get_node_or_null("Scroll/ContentCenter/Margin/MainVBox") as VBoxContainer
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
	var km_lab := vb.get_node_or_null("KeyModeRow/KeyModeLabel") as Label
	if km_lab:
		km_lab.text = tr("LABEL_KEY_MODE_NAME")
	var km_edit := vb.get_node_or_null("KeyModeRow/KeyModeTitleEdit") as LineEdit
	if km_edit:
		km_edit.placeholder_text = tr("PLACEHOLDER_KEY_MODE_CUSTOM")
	UiFont.bind_option_popups_in_tree(self, 17)


func _apply_theme() -> void:
	var pal := ThemePalette.get_palette(GameSettings.theme_id)
	var blended: Color = (pal["bg_top"] as Color).lerp(pal["bg_bottom"] as Color, 0.45)
	var bg_rect := get_node_or_null("ThemeBg") as ColorRect
	if bg_rect:
		bg_rect.color = blended

	var vb := get_node_or_null("Scroll/ContentCenter/Margin/MainVBox") as VBoxContainer
	if vb:
		var title := vb.get_node_or_null("Title") as Label
		if title:
			title.add_theme_color_override("font_color", pal["primary"])
		var sub := vb.get_node_or_null("Subtitle") as Label
		if sub:
			sub.add_theme_color_override("font_color", pal["muted"])
		var play := vb.get_node_or_null("PlaySudoku") as Button
		if play:
			UiFont.style_control_text(play, pal)
		var lang_l := vb.get_node_or_null("LangLabel") as Label
		if lang_l:
			lang_l.add_theme_color_override("font_color", pal["primary"])
		var theme_l := vb.get_node_or_null("ThemeLabel") as Label
		if theme_l:
			theme_l.add_theme_color_override("font_color", pal["primary"])
		var lo := vb.get_node_or_null("LangRow/LocaleOption") as OptionButton
		if lo:
			UiFont.style_option_button(lo, pal, 17)
		var to := vb.get_node_or_null("ThemeRow/ThemeOption") as OptionButton
		if to:
			UiFont.style_option_button(to, pal, 17)
		var km_lab := vb.get_node_or_null("KeyModeRow/KeyModeLabel") as Label
		if km_lab:
			km_lab.add_theme_color_override("font_color", pal["muted"])
		var km_edit := vb.get_node_or_null("KeyModeRow/KeyModeTitleEdit") as LineEdit
		if km_edit:
			UiFont.style_line_edit(km_edit, pal)
