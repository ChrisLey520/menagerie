extends Node
## 全局设置：语言、主题持久化（user://settings.cfg）

const SETTINGS_PATH := "user://settings.cfg"

const LOCALE_IDS: PackedStringArray = ["zh_CN", "zh_TW", "en"]
const THEME_IDS: PackedStringArray = ["forest", "ocean", "dawn", "dusk"]

signal locale_changed(code: String)
signal theme_changed(id: String)

var locale_code: String = "zh_CN":
	set(value):
		if locale_code == value:
			return
		locale_code = value
		TranslationServer.set_locale(value)
		save_settings()
		locale_changed.emit(value)

var theme_id: String = "forest":
	set(value):
		if theme_id == value:
			return
		theme_id = value
		save_settings()
		theme_changed.emit(value)


func _ready() -> void:
	load_settings()
	TranslationServer.set_locale(locale_code)


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("ui", "locale", locale_code)
	cf.set_value("ui", "theme", theme_id)
	cf.save(SETTINGS_PATH)


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	locale_code = cf.get_value("ui", "locale", "zh_CN")
	if locale_code not in LOCALE_IDS:
		locale_code = "zh_CN"
	theme_id = cf.get_value("ui", "theme", "forest")
	if theme_id not in THEME_IDS:
		theme_id = "forest"


func locale_display_index(code: String) -> int:
	return LOCALE_IDS.find(code)


func theme_display_index(id: String) -> int:
	return THEME_IDS.find(id)
