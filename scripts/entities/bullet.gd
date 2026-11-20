extends Area2D

const BURST_PLAYER_HIT: Color = Color(1.0, 0.86, 0.32, 1.0)
const BURST_ENEMY_HIT: Color = Color(0.95, 0.34, 0.34, 1.0)
const BURST_POOP: Color = Color(0.45, 0.30, 0.16, 1.0)
const BURST_DUST: Color = Color(0.62, 0.66, 0.72, 1.0)
const BURST_SWITCH: Color = Color(0.35, 0.95, 0.75, 1.0)

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
	if is_instance_valid(self):
		queue_free()


func _physics_process(delta):
	global_position += velocity * delta


func _on_body(body):
	if body == owner_ref:
		return
	if team == "player" and body.is_in_group("enemies") and body.has_method("take_damage"):
		# Игрок стреляет какашками — пуля лопается коричневым.
		GameEvents.request_burst("poop", global_position, BURST_POOP, velocity.normalized())
		body.take_damage(damage, global_position)
		queue_free()
		return
	if team == "enemy" and body.is_in_group("player") and body.has_method("take_damage"):
		# Кровь создаёт игрок в take_damage(): там учитывается его флаг
		# use_blood_particles и направление от точки попадания.
		# Передаём точку попадания: от неё зависит направление отброса и смерти.
		body.take_damage(damage, global_position)
		queue_free()
		return
	if team == "player" and body.is_in_group("destroyables") and body.has_method("take_damage"):
		GameEvents.request_burst("poop", global_position, BURST_POOP, velocity.normalized())
		body.take_damage(damage)
		queue_free()
		return
	if body.is_in_group("blocks") or body.is_in_group("pushables"):
		# Неподвижная пуля — это мина, она должна лежать на полу и
		# подрывать врагов, а не ломаться о блоки.
		if velocity.length() > 0.0:
			var wall_preset := "poop" if team == "player" else "dust"
			var wall_color := BURST_POOP if team == "player" else BURST_DUST
			GameEvents.request_burst(wall_preset, global_position, wall_color, velocity.normalized())
			queue_free()


func _on_area(area):
	if not area.has_method("on_bullet_hit"):
		return
	# Свитчи (и другие Area2D) реагируют только при явном by_bullet = true.
	# Иначе пуля летит дальше, как будто триггера нет.
	if not bool(area.get("by_bullet")):
		return
	if area.get("is_active") == false:
		return
	area.on_bullet_hit()
	GameEvents.request_burst("hit", global_position, BURST_SWITCH, velocity.normalized())
	queue_free()
