extends AnimatableBody2D
## Движущаяся платформа / скейт. Включается свитчем, возит игрока и
## разворачивается при столкновении со стеной (через RayCast2D).

@export var enable_move: bool = true
@export var move_speed: float = 10.0
@export var move_direction: int = 1
@export var ray_length: float = 26.0
@export var start_visible: bool = true
@export var start_active: bool = true
@export var listener_num: int = 0
@export var vis_on_switch: int = 0
@export var act_on_switch: int = 0
@export var rem_on_switch: int = 0

var moving: bool = false
var origin: Vector2 = Vector2.ZERO
var ray: RayCast2D = null


func _ready():
	sync_to_physics = true  # именно это заставляет платформу возить игрока
	visible = start_visible
	origin = global_position
	ray = RayCast2D.new()
	ray.target_position = Vector2(move_direction * ray_length, 0.0)
	add_child(ray)
	if enable_move and listener_num == 0:
		moving = true
	if listener_num > 0:
		add_to_group("switch_listeners")
	add_to_group("moving_blocks")


func on_switch_event(num: int, state: bool):
	if enable_move and state and (num == listener_num or listener_num == 0):
		moving = true
	if num != listener_num:
		return
	if rem_on_switch == 1 and state:
		queue_free()
		return
	if vis_on_switch == 1:
		visible = state
	if act_on_switch == 1:
		set_deferred("monitoring", state)


func on_nearby_switch(_pos: Vector2, _num: int):
	# Свитч-вопроситель стоит прямо на скейте — включаем по соседству.
	moving = true


func _physics_process(delta):
	if not moving or ray == null:
		return
	ray.target_position = Vector2(move_direction * ray_length, 0.0)
	if ray.is_colliding():
		move_direction *= -1
		ray.target_position = Vector2(move_direction * ray_length, 0.0)
	position.x += move_direction * move_speed * delta
