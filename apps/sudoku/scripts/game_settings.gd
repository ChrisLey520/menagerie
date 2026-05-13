extends Node
## 全局设置：语言、主题持久化（user://settings.cfg）

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_LOCALE: String = "zh_CN"

const LOCALE_IDS: PackedStringArray = ["zh_CN", "zh_TW", "en"]
const THEME_IDS: PackedStringArray = ["forest", "ocean", "dawn", "dusk"]

signal locale_changed(code: String)
signal theme_changed(id: String)

var locale_code: String = DEFAULT_LOCALE:
	set(value):
		if locale_code == value:
			return
		locale_code = value
		_apply_locale_to_engine(value)
		save_settings()
		locale_changed.emit(value)

var theme_id: String = "forest":
	set(value):
		if theme_id == value:
			return
		theme_id = value
		save_settings()
		theme_changed.emit(value)

## 数独「自定线索」模式按钮的自定义名称；空则使用翻译键 BTN_KEY_MODE
var key_mode_custom_title: String = "":
	set(value):
		if key_mode_custom_title == value:
			return
		key_mode_custom_title = value
		save_settings()

var _csv_translations_registered: bool = false


func _ready() -> void:
	load_settings()
	# Web 等平台上引擎 locale 可能在自动加载之后才就绪；延迟再对齐一次
	call_deferred("_deferred_sync_locale")


func _deferred_sync_locale() -> void:
	_apply_locale_to_engine(locale_code)
	# 首帧之后才就绪时，让已连接的界面用当前 locale 重刷文案（不写入 cfg）
	locale_changed.emit(locale_code)


## 注册 CSV 导入生成的 Translation，避免导出目标上未加入翻译域
func _ensure_translation_resources() -> void:
	if _csv_translations_registered:
		return
	for code in LOCALE_IDS:
		var path := "res://localization/translations.%s.translation" % code
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is Translation:
				TranslationServer.add_translation(res as Translation)
	_csv_translations_registered = true


## 使用所选语言对应的 Translation.locale 调用引擎（与导入资源一致，避免标准化不匹配）
func _apply_locale_to_engine(selection_code: String) -> void:
	_ensure_translation_resources()
	var path := "res://localization/translations.%s.translation" % selection_code
	var engine_locale := selection_code
	if ResourceLoader.exists(path):
		var tr_res := load(path) as Translation
		if tr_res != null and not str(tr_res.locale).is_empty():
			engine_locale = str(tr_res.locale)
	TranslationServer.set_locale(engine_locale)


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("ui", "locale", locale_code)
	cf.set_value("ui", "theme", theme_id)
	cf.set_value("ui", "key_mode_custom_title", key_mode_custom_title)
	cf.save(SETTINGS_PATH)


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		_apply_locale_to_engine(DEFAULT_LOCALE)
		return
	var loc := str(cf.get_value("ui", "locale", DEFAULT_LOCALE))
	if loc not in LOCALE_IDS:
		loc = DEFAULT_LOCALE
	var th := str(cf.get_value("ui", "theme", "forest"))
	if th not in THEME_IDS:
		th = "forest"
	var km := str(cf.get_value("ui", "key_mode_custom_title", ""))

	if locale_code != loc:
		locale_code = loc
	if theme_id != th:
		theme_id = th
	if key_mode_custom_title != km:
		key_mode_custom_title = km
	# 当 cfg 中的 locale 与默认值相同（如均为 zh_CN）时，locale setter 会短路，
	# 引擎仍停留在浏览器/OS 语言（常为 en）。必须在读档后强制对齐 TranslationServer。
	_apply_locale_to_engine(loc)


func locale_display_index(code: String) -> int:
	return LOCALE_IDS.find(code)


func theme_display_index(id: String) -> int:
	return THEME_IDS.find(id)
