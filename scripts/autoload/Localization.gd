extends Node
## База локализации: пока переводим только кнопки.
## Чтобы добавить язык — добавь словарь в DICTIONARIES и код в SUPPORTED.

const SUPPORTED := ["ru", "en"]
var DICTIONARIES := {
	"en": {
		"START": "START",
		"Продолжить": "CONTINUE",
		"Попробовать ещё раз": "TRY AGAIN",
		"Попробовать еще раз": "TRY AGAIN",
		"Настройки": "SETTINGS",
		"Пауза": "PAUSED",
		"Продолжить игру": "RESUME",
		"В главное меню": "MAIN MENU",
		"Выход": "QUIT",
	},
}


func _ready() -> void:
	for locale in DICTIONARIES.keys():
		var tr = Translation.new()
		tr.locale = locale
		for key in DICTIONARIES[locale].keys():
			tr.add_message(key, DICTIONARIES[locale][key])
		TranslationServer.add_translation(tr)
	# По умолчанию оставляем русский; переключение — set_locale("en").

func set_locale(code: String) -> void:
	if SUPPORTED.has(code):
		TranslationServer.set_locale(code)
		get_tree().call_group("localized_buttons", "refresh_text")

func toggle() -> void:
	set_locale("en" if TranslationServer.get_locale() != "en" else "ru")

func translate_button(btn: Button) -> void:
	btn.add_to_group("localized_buttons")
	btn.set_meta("source_text", btn.text)
	btn.text = tr(btn.text)

func refresh_buttons() -> void:
	get_tree().call_group("localized_buttons", "refresh_text")
