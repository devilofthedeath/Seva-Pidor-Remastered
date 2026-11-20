extends CharacterBody2D

@export var pushed_switch: int = 0
@export var gc_id: String = ""
@export var start_visible: bool = true
@export var listener_num: int = 0
@export var rem_on_switch: int = 0
@export var use_gravity: bool = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var origin: Vector2 = Vector2.ZERO
var triggered: bool = false


func _ready():
	# Слой 3: сталкиваемся с миром и игроком, но не с врагами.
	collision_layer = 4  # бит 3
	collision_mask = 3  # слои 1 + 2
	visible = start_visible
	origin = global_position
	velocity = Vector2.ZERO
	if listener_num > 0:
		add_to_group("switch_listeners")


func on_switch_event(num: int, state: bool):
	if num == listener_num and state:
		global_position = origin
		velocity = Vector2.ZERO
		triggered = false


func _physics_process(delta):
	if use_gravity and not is_on_floor():
		velocity.y += gravity * delta
	elif is_on_floor():
		velocity.y = 0.0

	# Толкаем по НАЖАТИЮ игрока, а не по его скорости: когда он стоит впритык,
	# коллизия обнуляет velocity, но кнопка движения всё ещё нажата.
	var input_dir := Input.get_axis("ui_left", "ui_right")
	var push := 0.0
	for body in get_tree().get_nodes_in_group("player"):
		var dx = global_position.x - body.global_position.x
		var dy = abs(global_position.y - body.global_position.y)
		if abs(dx) < 64.0 and dy < 62.0 and abs(input_dir) > 0.1 and sign(input_dir) == sign(dx):
			var pspeed := float(body.get("speed")) if body.get("speed") != null else 140.0
			push = sign(dx) * max(90.0, abs(pspeed) * 0.7)
	if abs(push) > 1.0:
		velocity.x = push
	else:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_and_slide()

	if not triggered and global_position.distance_to(origin) > 40.0:
		triggered = true
		if pushed_switch > 0:
			GameState.trigger_switch(pushed_switch, 1)
		if gc_id != "":
			GameState.mark_cleared(gc_id)
