extends Node
## Пауза по Esc или кнопке START геймпада.
## Оверлей живёт в autoload, поэтому не пропадает при смене сцен.

signal paused_changed(value: bool)

var is_paused: bool = false
var _layer: CanvasLayer
var _resume_button: Button
var _menu_button: Button


func _ready() -> void:
	# Работаем и когда дерево на паузе.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause() -> void:
	set_paused(not get_tree().paused)


func set_paused(value: bool) -> void:
	if get_tree().paused == value:
		return
	get_tree().paused = value
	is_paused = value
	_layer.visible = value
	paused_changed.emit(value)
	if value:
		_resume_button.grab_focus()
	else:
		_resume_button.release_focus()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_layer.visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)

	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -120.0
	panel.offset_top = -86.0
	panel.offset_right = 120.0
	panel.offset_bottom = 86.0
	panel.add_theme_constant_override("separation", 10)
	_layer.add_child(panel)

	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	panel.add_child(title)

	var hint := Label.new()
	hint.text = "Esc / START — продолжить"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)

	_resume_button = Button.new()
	_resume_button.name = "ResumeButton"
	_resume_button.text = "Продолжить"
	_resume_button.custom_minimum_size = Vector2(0.0, 30.0)
	_resume_button.pressed.connect(_on_resume_pressed)
	panel.add_child(_resume_button)

	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.text = "В главное меню"
	_menu_button.custom_minimum_size = Vector2(0.0, 30.0)
	_menu_button.pressed.connect(_on_menu_pressed)
	panel.add_child(_menu_button)

	# Навигация геймпадом: вниз/вверх между кнопками, A — нажать.
	_resume_button.focus_neighbor_bottom = NodePath("../MenuButton")
	_menu_button.focus_neighbor_top = NodePath("../ResumeButton")


func _on_resume_pressed() -> void:
	set_paused(false)


func _on_menu_pressed() -> void:
	set_paused(false)
	get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")
