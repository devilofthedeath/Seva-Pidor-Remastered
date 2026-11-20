extends StaticBody2D

@export var start_visible: bool = true
@export var start_active: bool = true
@export var listener_num: int = 0
@export var vis_on_switch: int = 0
@export var act_on_switch: int = 0
@export var rem_on_switch: int = 0
@export var enable_move: bool = false
@export var move_speed: float = 0.0
@export var move_direction: int = 1

var moving: bool = false


func _ready():
	visible = start_visible
	# Невидимая стена остаётся твёрдой — выключаем только отрисовку.
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", not start_active)
	if listener_num > 0 or enable_move:
		add_to_group("switch_listeners")
	if enable_move and listener_num == 0:
		moving = true


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
	if act_on_switch == 1 and has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", not state)


# Свитч, включивший движение, может стоять прямо на блоке (например, знак
# вопроса над скейтом) — включаем платформу по соседству, а не только по номеру.
func on_nearby_switch(pos: Vector2, _num: int):
	if enable_move and global_position.distance_to(pos) < 70.0:
		moving = true


func _physics_process(delta):
	if moving and move_speed > 0.0:
		position.x += move_direction * move_speed * delta
