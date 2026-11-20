extends Node
## Базовые настройки игры: громкость и язык.
## Пока язык — заглушка (только сохраняется), громкость реально влияет на Master.

signal settings_changed

const CONFIG_PATH: String = "user://settings.cfg"
const LANGUAGE_RU: String = "ru"
const LANGUAGE_EN: String = "en"

var volume: int = 80
var language: String = LANGUAGE_RU


func _ready() -> void:
	load_settings()
	apply_audio()


func set_volume(value: int) -> void:
	volume = clampi(value, 0, 100)
	apply_audio()
	save_settings()
	settings_changed.emit()


func set_language(value: String) -> void:
	language = value if value in [LANGUAGE_RU, LANGUAGE_EN] else LANGUAGE_RU
	save_settings()
	settings_changed.emit()


func apply_audio() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		return
	if volume <= 0:
		AudioServer.set_bus_mute(master, true)
	else:
		AudioServer.set_bus_mute(master, false)
		AudioServer.set_bus_volume_db(master, linear_to_db(float(volume) / 100.0))


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	volume = clampi(int(cfg.get_value("audio", "volume", volume)), 0, 100)
	language = str(cfg.get_value("localization", "language", language))
	if language not in [LANGUAGE_RU, LANGUAGE_EN]:
		language = LANGUAGE_RU


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("localization", "language", language)
	cfg.save(CONFIG_PATH)
