extends Button
## Кнопка, текст которой автоматически переводится.

func _ready() -> void:
	if not is_in_group("localized_buttons"):
		Localization.translate_button(self)

func refresh_text() -> void:
	if has_meta("source_text"):
		text = tr(String(get_meta("source_text")))
