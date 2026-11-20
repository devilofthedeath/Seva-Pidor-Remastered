extends Node
## Навигация по уровням, победа/проигрыш, ретрай.
## Раньше всё это жило в GameState.

var level_order: Array = ['res://scenes/levels/LEVEL_2.tscn', 'res://scenes/levels/LEVEL_3.tscn', 'res://scenes/levels/LEVEL_4.tscn', 'res://scenes/levels/LEVEL_5.tscn', 'res://scenes/levels/LEVEL_6.tscn', 'res://scenes/levels/LEVEL_7.tscn', 'res://scenes/levels/LEVEL_8.tscn', 'res://scenes/levels/LEVEL_9.tscn', 'res://scenes/levels/LEVEL_10.tscn', 'res://scenes/levels/LEVEL_11.tscn', 'res://scenes/levels/LEVEL_12.tscn', 'res://scenes/levels/LEVEL_13.tscn', 'res://scenes/levels/LEVEL_14.tscn', 'res://scenes/levels/LEVEL_15.tscn', 'res://scenes/levels/LEVEL_16.tscn', 'res://scenes/levels/LEVEL_17.tscn', 'res://scenes/levels/LEVEL_18.tscn', 'res://scenes/levels/LEVEL_19.tscn', 'res://scenes/levels/LEVEL_20.tscn']
var level_by_number: Dictionary = {2: 'res://scenes/levels/LEVEL_2.tscn', 3: 'res://scenes/levels/LEVEL_3.tscn', 4: 'res://scenes/levels/LEVEL_4.tscn', 5: 'res://scenes/levels/LEVEL_5.tscn', 10: 'res://scenes/levels/LEVEL_10.tscn', 16: 'res://scenes/levels/LEVEL_16.tscn', 6: 'res://scenes/levels/LEVEL_6.tscn', 7: 'res://scenes/levels/LEVEL_7.tscn', 8: 'res://scenes/levels/LEVEL_8.tscn', 9: 'res://scenes/levels/LEVEL_9.tscn', 11: 'res://scenes/levels/LEVEL_11.tscn', 18: 'res://scenes/levels/LEVEL_18.tscn', 19: 'res://scenes/levels/LEVEL_19.tscn', 12: 'res://scenes/levels/LEVEL_12.tscn', 13: 'res://scenes/levels/LEVEL_13.tscn', 14: 'res://scenes/levels/LEVEL_14.tscn', 15: 'res://scenes/levels/LEVEL_15.tscn', 17: 'res://scenes/levels/LEVEL_17.tscn', 20: 'res://scenes/levels/LEVEL_20.tscn'}
var known_switches: Array = [1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 30, 31, 32, 33, 34, 35, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 75, 76, 100]

var victory_scene: String = "res://scenes/levels/titles.tscn"
var lose_scene: String = "res://scenes/levels/game_over.tscn"


func change_scene(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		push_warning("SceneRouter: сцена не найдена: " + path)
		return
	GameEvents.emit_level_changed(path)
	get_tree().change_scene_to_file(path)


func go_to_level(num: int) -> void:
	if level_by_number.has(num):
		change_scene(level_by_number[num])


func next_level() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var idx := level_order.find(scene.scene_file_path)
	if idx >= 0 and idx + 1 < level_order.size():
		change_scene(level_order[idx + 1])
	elif victory_scene != "":
		change_scene(victory_scene)
	else:
		get_tree().reload_current_scene()


func kill_player() -> void:
	RunState.set_hp(0)
	var scene = get_tree().current_scene
	if scene != null and scene.scene_file_path != lose_scene:
		RunState.last_death_scene = scene.scene_file_path
	if lose_scene != "":
		change_scene(lose_scene)
	else:
		get_tree().reload_current_scene()


func retry_level() -> void:
	RunState.reset_for_level()
	if RunState.last_death_scene != "":
		change_scene(RunState.last_death_scene)
	else:
		get_tree().reload_current_scene()


func on_timer_action(action: int, param: int) -> void:
	if param <= 0:
		return
	match action:
		2, 1:
			RunState.trigger_switch(param, 1)
		3:
			# action=3 обычно дёргает свитч; если номера совпадают с уровнем
			# и такого свитча нет — идём на уровень.
			if known_switches.has(param) or not level_by_number.has(param):
				RunState.trigger_switch(param, 1)
			else:
				go_to_level(param)
