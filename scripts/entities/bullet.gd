extends Area2D

@export var team: String = "enemy"
@export var velocity: Vector2 = Vector2(100, 0)
@export var damage: int = 10
@export var lifetime: float = 2.0

var owner_ref: Node = null
var owner_id: String = ""


func _ready():
	# Пули видят все слои: блоки (1), актёров (2), ящики (3).
	collision_layer = 4
	collision_mask = 7  # все три слоя
	add_to_group("bullets")
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)
	await get_tree().create_timer(max(0.05, lifetime)).timeout
	queue_free()


func _physics_process(delta):
	global_position += velocity * delta


func _on_body(body):
	if body == owner_ref:
		return
	if team == "player" and body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return
	if team == "enemy" and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return
	if team == "player" and body.is_in_group("destroyables") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return
	if body.is_in_group("blocks") or body.is_in_group("pushables"):
		# Неподвижная пуля — это мина, она должна лежать на полу и
		# подрывать врагов, а не ломаться о блоки.
		if velocity.length() > 0.0:
			queue_free()


func _on_area(area):
	if area.has_method("on_bullet_hit"):
		area.on_bullet_hit()
		queue_free()
