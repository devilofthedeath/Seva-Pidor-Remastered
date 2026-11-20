extends Node
## Только сохранение/загрузка. Раньше жило в GameState.

const SAVE_PATH: String = "user://seva_save.cfg"


func has_save() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	file.close()
	return true


func save_game() -> bool:
	var scene = get_tree().current_scene
	if scene == null:
		return false
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "scene", scene.scene_file_path)
	cfg.set_value("progress", "hp", RunState.hp)
	cfg.set_value("progress", "score", RunState.score)
	cfg.set_value("progress", "keys", RunState.keys)
	return cfg.save(SAVE_PATH) == OK


func load_game() -> bool:
	if not has_save():
		return false
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	var scene_path := str(cfg.get_value("progress", "scene", ""))
	RunState.hp = clampi(int(cfg.get_value("progress", "hp", RunState.max_hp)), 0, RunState.max_hp)
	GameEvents.emit_hp(RunState.hp, RunState.max_hp)
	RunState.score = int(cfg.get_value("progress", "score", 0))
	GameEvents.emit_score(RunState.score)
	RunState.keys = int(cfg.get_value("progress", "keys", 0))
	GameEvents.emit_keys(RunState.keys)
	if scene_path != "":
		SceneRouter.change_scene(scene_path)
	return true
