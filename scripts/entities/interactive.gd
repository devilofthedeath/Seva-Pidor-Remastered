extends Area2D

@export var role: String = "DESIGN"
@export var start_visible: bool = true
@export var start_active: bool = true
@export var listener_num: int = 0
@export var vis_on_switch: int = 0
@export var act_on_switch: int = 0
@export var rem_on_switch: int = 0
@export var switch_num: int = 0
@export var switch_mode: int = 2
@export var by_bullet: bool = false
@export var by_melee: bool = false
@export var ignore_player: bool = false
@export var action_score: int = 0
@export var action_health: int = 0
@export var damage: int = 25
@export var popup_index: int = 0
@export var grant_gun: bool = false
@export var timer_id: int = 0
@export var timer_secs: float = 0.0
@export var activated_tex: Texture2D
@export var once: bool = false
@export var need_score: int = 0
@export var need_cleared: String = ""
@export var gc_id: String = ""

var is_active: bool = true
var switched: bool = false
var finish_done: bool = false


func _ready():
	visible = start_visible
	is_active = start_active
	set_deferred("monitoring", start_active)
	if listener_num > 0 or role == "DOOR" or role == "SWITCH":
		add_to_group("switch_listeners")
	body_entered.connect(_on_body)


func on_switch_event(num: int, state: bool):
	if role == "DOOR" and num == listener_num:
		visible = not state
		set_deferred("monitoring", not state)
		return
	# Сам переключатель меняет спрайт, когда срабатывает его номер.
	if role == "SWITCH" and num == switch_num:
		_set_switched(state)
		return
	if num != listener_num:
		return
	if rem_on_switch == 1 and state:
		queue_free()
		return
	if vis_on_switch == 1:
		visible = state
	if act_on_switch == 1:
		is_active = state
		set_deferred("monitoring", state)


func _set_switched(state: bool):
	switched = state
	if activated_tex != null and has_node("Sprite2D"):
		$Sprite2D.texture = activated_tex
		$Sprite2D.hframes = 1


func _activate_switch():
	if not is_active or (once and switched):
		return
	GameState.trigger_switch(switch_num, switch_mode)
	get_tree().call_group("moving_blocks", "on_nearby_switch", global_position, switch_num)
	if popup_index > 0:
		GameState.show_popup(popup_index)


func _can_finish() -> bool:
	if need_score > 0 and GameState.score < need_score:
		return false
	if need_cleared != "" and not GameState.is_cleared(need_cleared):
		return false
	return true


# У уровней 3–5 финиш висит в воздухе, но должен срабатывать сразу после
# убийства нужного врага (check_type_cleared) — без прикосновения к зоне.
func _process(_delta):
	if role == "FINISH LEVEL" and not finish_done and need_cleared != "" and _can_finish():
		finish_done = true
		GameState.next_level()


func _on_body(body):
	if not is_active or not body.is_in_group("player"):
		return
	if role in ["COLLECTABLE", "POWERUP", "KEY", "BONUS"]:
		if role == "KEY":
			GameState.keys += 1
		if action_score != 0:
			GameState.add_score(action_score)
		if action_health > 0 and body.has_method("heal"):
			body.heal(action_health)
		if grant_gun:
			body.has_gun = true
		if popup_index > 0:
			GameState.show_popup(popup_index)
		if timer_id > 0:
			GameState.start_timer(timer_id, timer_secs)
		if gc_id != "":
			GameState.mark_cleared(gc_id)
		queue_free()
	elif role == "SWITCH" and not ignore_player:
		_activate_switch()
	elif role == "HURTING ZONE":
		if body.has_method("take_damage"):
			body.take_damage(damage)
	elif role == "TELEPORT START":
		var ends = get_tree().get_nodes_in_group("teleport_end")
		if ends.size() > 0:
			body.global_position = ends.front().global_position
	elif role == "FINISH LEVEL":
		if _can_finish():
			GameState.next_level()


func on_bullet_hit():
	# Пуля активирует объект только при явном by_bullet = true.
	if role == "SWITCH" and by_bullet and is_active:
		_activate_switch()


func on_melee_hit():
	if role == "SWITCH":
		_activate_switch()
