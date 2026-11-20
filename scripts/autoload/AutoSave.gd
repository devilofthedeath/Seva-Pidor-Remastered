extends Node

# На этих уровнях делаем автосохранение.
const SAVE_LEVELS := [3, 6, 8, 11, 12, 17, 18, 19]
var banner: Label = null
var layer: CanvasLayer = null


func _ready() -> void:
	# Важно: autoload создаётся ОДИН раз. Следим за каждой сменой сцены,
	# иначе сохранение срабатывало бы только при самом первом запуске игры.
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_check")


# В Godot 4.7 SceneTree.scene_changed приходит БЕЗ аргументов.
# Если объявить обязательный параметр — будет ошибка на каждой смене сцены.
func _on_scene_changed(_old_scene = null, _new_scene = null) -> void:
	call_deferred("_check")


func _check() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var path: String = scene.scene_file_path
	var parts := path.get_file().get_basename().split("_")
	if parts.size() < 2 or not parts[1].is_valid_int():
		return
	if not SAVE_LEVELS.has(int(parts[1])):
		return
	_show_banner("СОХРАНЕНИЕ...")
	GameState.save_game()
	await get_tree().create_timer(1.3).timeout
	if banner != null:
		banner.queue_free()
		banner = null


func _show_banner(text: String) -> void:
	if banner != null:
		banner.queue_free()
	layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	banner = Label.new()
	banner.text = text
	banner.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	banner.offset_left = -150.0
	banner.offset_top = 12.0
	banner.offset_right = -12.0
	banner.offset_bottom = 40.0
	layer.add_child(banner)
