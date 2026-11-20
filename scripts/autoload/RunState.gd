extends Node
## Состояние текущего прохождения: hp, score, keys, свитчи, флаги.
## Всё, что раньше хранилось в GameState и относилось к «рану».

var hp: int = 100
var max_hp: int = 100
var score: int = 0
var keys: int = 0
var cleared: Dictionary = {}
var switches: Dictionary = {}
var dialogue_active: bool = false
var level_bottom: int = 100000
var last_death_scene: String = ""


func set_hp(value: int) -> void:
	hp = clampi(value, 0, max_hp)
	GameEvents.emit_hp(hp, max_hp)


func heal(amount: int) -> void:
	set_hp(hp + amount)


func add_score(points: int) -> void:
	score += points
	GameEvents.emit_score(score)


func add_keys(amount: int = 1) -> void:
	keys += amount
	GameEvents.emit_keys(keys)


func set_dialogue_active(value: bool) -> void:
	if dialogue_active == value:
		return
	dialogue_active = value
	GameEvents.emit_dialogue(value)


func mark_cleared(obj_id: String) -> void:
	if obj_id == "":
		return
	cleared[obj_id] = true


func is_cleared(obj_id: String) -> bool:
	return cleared.get(obj_id, false)


func set_switch(num: int, state: bool) -> void:
	if num <= 0:
		return
	switches[num] = state
	GameEvents.emit_switch(num, state)
	# Обратная совместимость со старыми Obj_*.tscn, которые слушают группу.
	get_tree().call_group("switch_listeners", "on_switch_event", num, state)


func trigger_switch(num: int, mode: int = 2) -> void:
	if num <= 0:
		return
	var next_state: bool = not switches.get(num, false) if mode == 2 else true
	set_switch(num, next_state)


func start_timer(tid: int, seconds: float) -> void:
	if tid <= 0:
		return
	GameEvents.emit_timer(tid, seconds)
	# Обратная совместимость со старыми HUD-таймерами.
	get_tree().call_group("game_timers", "on_start_timer", tid, seconds)


func reset_for_level() -> void:
	hp = max_hp
	GameEvents.emit_hp(hp, max_hp)
