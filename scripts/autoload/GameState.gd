extends Node
## Compatibility facade. Логика разнесена:
## RunState — состояние раунда, SceneRouter — уровни, SaveService — сохранения,
## DialogueService — диалоги, GameEvents — сигналы.
## Старые вызовы GameState.xxx продолжают работать.

var hp: int:
	get:
		return RunState.hp
	set(value):
		RunState.set_hp(value)

var max_hp: int:
	get:
		return RunState.max_hp
	set(value):
		RunState.max_hp = maxi(1, value)
		GameEvents.emit_hp(RunState.hp, RunState.max_hp)

var score: int:
	get:
		return RunState.score
	set(value):
		RunState.score = value
		GameEvents.emit_score(value)

var keys: int:
	get:
		return RunState.keys
	set(value):
		RunState.keys = value
		GameEvents.emit_keys(value)

var cleared: Dictionary:
	get:
		return RunState.cleared
	set(value):
		RunState.cleared = value

var switches: Dictionary:
	get:
		return RunState.switches
	set(value):
		RunState.switches = value

var dialogue_active: bool:
	get:
		return RunState.dialogue_active
	set(value):
		RunState.set_dialogue_active(value)

var level_bottom: int:
	get:
		return RunState.level_bottom
	set(value):
		RunState.level_bottom = value

var last_death_scene: String:
	get:
		return RunState.last_death_scene
	set(value):
		RunState.last_death_scene = value

var popups: Dictionary:
	get:
		return DialogueService.popups
	set(value):
		DialogueService.popups = value

var is_popup_open: bool:
	get:
		return DialogueService.is_popup_open

var SAVE_PATH: String:
	get:
		return SaveService.SAVE_PATH

var level_order: Array:
	get:
		return SceneRouter.level_order

var level_by_number: Dictionary:
	get:
		return SceneRouter.level_by_number

var known_switches: Array:
	get:
		return SceneRouter.known_switches

var victory_scene: String:
	get:
		return SceneRouter.victory_scene
	set(value):
		SceneRouter.victory_scene = value

var lose_scene: String:
	get:
		return SceneRouter.lose_scene
	set(value):
		SceneRouter.lose_scene = value


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# --- Состояние ---
func trigger_switch(num: int, mode: int = 2) -> void:
	RunState.trigger_switch(num, mode)

func start_timer(tid: int, secs: float) -> void:
	RunState.start_timer(tid, secs)

func add_score(pts: int) -> void:
	RunState.add_score(pts)

func mark_cleared(obj_id: String) -> void:
	RunState.mark_cleared(obj_id)

func is_cleared(obj_id: String) -> bool:
	return RunState.is_cleared(obj_id)


# --- Диалоги ---
func show_popup(idx: int) -> void:
	DialogueService.show_popup(idx)


# --- Сцены ---
func kill_player() -> void:
	SceneRouter.kill_player()

func retry_level() -> void:
	SceneRouter.retry_level()

func go_to_level(num: int) -> void:
	SceneRouter.go_to_level(num)

func next_level() -> void:
	SceneRouter.next_level()

func on_timer_action(action: int, param: int) -> void:
	SceneRouter.on_timer_action(action, param)


# --- Сохранения ---
func has_save() -> bool:
	return SaveService.has_save()

func save_game() -> bool:
	return SaveService.save_game()

func load_game() -> bool:
	return SaveService.load_game()
