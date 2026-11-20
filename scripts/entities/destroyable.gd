extends StaticBody2D

@export var max_hp: int = 1
@export var hp: int = 1
@export var infinite_health: bool = false
@export var destroy_score: int = 0
@export var destroy_switch: int = 0
@export var ignore_bullets: bool = false
@export var destroy_tex: Texture2D
@export var gc_id: String = ""
@export var start_visible: bool = true
@export var start_active: bool = true
@export var listener_num: int = 0
@export var vis_on_switch: int = 0
@export var act_on_switch: int = 0
@export var rem_on_switch: int = 0

var is_dead: bool = false


func _ready():
	visible = start_visible
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", not start_active)
	if listener_num > 0:
		add_to_group("switch_listeners")


func on_switch_event(num: int, state: bool):
	if num != listener_num:
		return
	if rem_on_switch == 1 and state:
		queue_free()
		return
	if vis_on_switch == 1:
		visible = state
	if act_on_switch == 1 and has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", not state)


func take_damage(amount: int, _from = null):
	if is_dead or not start_active or ignore_bullets:
		return
	if not infinite_health:
		hp -= amount
	if infinite_health or hp > 0:
		return
	is_dead = true
	GameEvents.request_burst("death", global_position, Color(0.72, 0.66, 0.55, 1.0))
	if destroy_score > 0:
		GameState.add_score(destroy_score)
	if destroy_switch > 0:
		GameState.trigger_switch(destroy_switch, 1)
	if gc_id != "":
		GameState.mark_cleared(gc_id)
	if destroy_tex != null and has_node("Sprite2D"):
		$Sprite2D.texture = destroy_tex
		$Sprite2D.hframes = 1
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		queue_free()
