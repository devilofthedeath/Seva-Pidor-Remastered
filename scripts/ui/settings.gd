extends Control
## Экран настроек: громкость Master и язык (пока заглушка).

var _volume_slider: HSlider
var _volume_value: Label
var _language_option: OptionButton


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.065, 0.11, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -170.0
	panel.offset_top = -118.0
	panel.offset_right = 170.0
	panel.offset_bottom = 118.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 9)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "НАСТРОЙКИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 8)
	vbox.add_child(volume_row)

	var volume_label := Label.new()
	volume_label.text = "Громкость"
	volume_label.custom_minimum_size = Vector2(92.0, 0.0)
	volume_row.add_child(volume_label)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 1.0
	_volume_slider.value = SettingsService.volume
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_row.add_child(_volume_slider)
	_volume_slider.value_changed.connect(_on_volume_changed)

	_volume_value = Label.new()
	_volume_value.text = "%d%%" % SettingsService.volume
	_volume_value.custom_minimum_size = Vector2(44.0, 0.0)
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_row.add_child(_volume_value)

	var language_row := HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 8)
	vbox.add_child(language_row)

	var language_label := Label.new()
	language_label.text = "Язык"
	language_label.custom_minimum_size = Vector2(92.0, 0.0)
	language_row.add_child(language_label)

	_language_option = OptionButton.new()
	_language_option.add_item("Русский", 0)
	_language_option.add_item("English", 1)
	_language_option.selected = 0 if SettingsService.language == SettingsService.LANGUAGE_RU else 1
	_language_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_row.add_child(_language_option)
	_language_option.item_selected.connect(_on_language_selected)

	var hint := Label.new()
	hint.text = "Язык пока сохраняется как заглушка."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.65, 0.68, 0.76, 1.0))
	vbox.add_child(hint)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var back := Button.new()
	back.text = "Назад"
	back.custom_minimum_size = Vector2(0.0, 30.0)
	back.pressed.connect(_on_back_pressed)
	vbox.add_child(back)


func _on_volume_changed(value: float) -> void:
	SettingsService.set_volume(int(value))
	_volume_value.text = "%d%%" % SettingsService.volume


func _on_language_selected(index: int) -> void:
	SettingsService.set_language(SettingsService.LANGUAGE_RU if index == 0 else SettingsService.LANGUAGE_EN)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")
