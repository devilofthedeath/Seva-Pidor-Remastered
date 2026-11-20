extends Area2D
## Общая база для всех интерактивных объектов. Специфику смотри в scripts/roles/.

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
@export var once: bool = false
@export var action_score: int = 0
@export var action_health: int = 0
@export var damage: int = 25
@export var popup_index: int = 0
@export var grant_gun: bool = false
@export var timer_id: int = 0
@export var timer_secs: float = 0.0
@export var need_score: int = 0
@export var need_cleared: String = ""
@export var gc_id: String = ""
@export var activated_tex: Texture2D

var is_active: bool = true
var switched: bool = false


func _ready():
	# Триггеры видят актёров на любом слое.
	collision_mask = 7  # все три слоя
	visible = start_visible
	is_active = start_active
	set_deferred("monitoring", start_active)
	if listener_num > 0 or role == "DOOR" or role == "SWITCH" or role == "FINISH LEVEL":
		add_to_group("switch_listeners")
	if role == "TELEPORT END":
		add_to_group("teleport_end")
	body_entered.connect(_on_body)


func on_switch_event(num: int, state: bool):
	_on_switch_special(num, state)
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


func _on_switch_special(_num: int, _state: bool):
	pass


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


func _on_body(_body):
	pass


func on_bullet_hit():
	pass


func on_melee_hit():
	pass
