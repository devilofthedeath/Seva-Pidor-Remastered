extends Node
## F4 = fullscreen в стиле Undertale: окно становится полноэкранным,
## но игровое поле остаётся 480x320 и по краям появляются чёрные рамки.

@export var start_fullscreen: bool = false
## Соотношение сторон в полноэкранном режиме (KEEP = чёрные поля вокруг картинки).
@export var fullscreen_aspect: int = Window.CONTENT_SCALE_ASPECT_KEEP
## Соотношение сторон в обычном окне (EXPAND = как в проекте сейчас).
@export var windowed_aspect: int = Window.CONTENT_SCALE_ASPECT_EXPAND

var _is_fullscreen: bool = false


func _ready() -> void:
	# Работает даже пока идёт диалог/пауза.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = windowed_aspect
	if start_fullscreen:
		_set_fullscreen(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen", false, true):
		_set_fullscreen(not _is_fullscreen)
		get_viewport().set_input_as_handled()


func _set_fullscreen(enable: bool) -> void:
	var win := get_window()
	if enable:
		win.mode = Window.MODE_FULLSCREEN
		win.content_scale_aspect = fullscreen_aspect
	else:
		win.mode = Window.MODE_WINDOWED
		win.content_scale_aspect = windowed_aspect
	_is_fullscreen = enable


func is_fullscreen() -> bool:
	return _is_fullscreen


## Можно дёрнуть из кода/кнопки меню, а не только клавишей F4.
func set_fullscreen(enable: bool) -> void:
	_set_fullscreen(enable)
