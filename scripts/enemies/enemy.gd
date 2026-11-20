extends CharacterBody2D

@export var mode: String = "platformer"
@export var speed: float = 90.0
@export var max_hp: int = 30
@export var hp: int = 30
@export var infinite_health: bool = false
@export var contact_damage: int = 10
@export var use_gravity: bool = true
@export var move_dir_mode: int = 1
@export var move_shape: int = 0
@export var towards_player: int = 0
@export var random_direction: int = 0
@export var ignore_objects: bool = false
@export var turn_to_player: int = 0
@export var boss: bool = false
@export var phase: int = 0
@export var can_shoot: bool = false
## Рукопашная атака рывком (для врагов без пуль).
@export var melee_enabled: bool = true
@export var melee_range: float = 72.0
@export var melee_lunge_speed: float = 300.0
## Сам рывок: скорость и длительность перед ударом.
@export var melee_dash_speed: float = 650.0
@export var melee_dash_time: float = 0.18
@export var melee_cooldown: float = 1.3
@export var melee_damage: int = 0
@export var shoot_dir: int = 0
@export var bullet_speed: float = 300.0
@export var bullet_damage: int = 10
@export var bullet_max_count: int = 1
@export var bullet_lifetime: float = 2.0
@export var shoot_interval: float = 1.0
@export var bullet_tex: Texture2D
@export var bullet_shape: Vector2 = Vector2(10, 8)
@export var tex_hit: Texture2D
@export var frames_hit: int = 1
@export var gc_id: String = ""
@export var death_switch: int = 0
@export var show_health_bar: bool = false
@export var health_bar_width: int = 40
@export var health_bar_height: int = 6
@export var health_bar_color: Color = Color(0.714, 0.235, 0.208, 1)
@export var health_bar_offset: float = -20.0
@export var start_visible: bool = true
@export var start_active: bool = true
@export var listener_num: int = 0
@export var vis_on_switch: int = 0
@export var act_on_switch: int = 0
@export var rem_on_switch: int = 0

var dir: int = -1
var move_vec: Vector2 = Vector2.LEFT
var random_timer: float = 0.0
var is_active: bool = true
var is_aggro: bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var shoot_timer: float = 0.0
var contact_timer: float = 0.0
var age: float = 0.0
var origin: Vector2 = Vector2.ZERO
var knockback: Vector2 = Vector2.ZERO
var knock_timer: float = 0.0
var melee_timer: float = 0.0
var melee_area: Area2D = null
var melee_dashing: bool = false
var melee_dash_timer: float = 0.0
var melee_dash_dir: Vector2 = Vector2.ZERO
var melee_hit_done: bool = false
var hp_bar: ProgressBar = null


func _ready():
	# Враги живут на слое 2 и сталкиваются только с миром (слой 1),
	# поэтому не толкают ящики (слой 3) и не пихают игрока физикой.
	collision_layer = 2
	collision_mask = 1
	visible = start_visible
	is_active = start_active
	# Патруль начинает строго с направления из .obj, а не с LEFT по умолчанию.
	if move_dir_mode == 1:
		move_vec = Vector2.LEFT
	elif move_dir_mode == 2:
		move_vec = Vector2.RIGHT
	origin = global_position
	shoot_timer = randf() * max(0.1, shoot_interval)
	if listener_num > 0:
		add_to_group("switch_listeners")
	# Area2D как «чувство ближнего боя»: как только игрок вошёл в радиус — рывок.
	if melee_enabled:
		melee_area = Area2D.new()
		melee_area.collision_layer = 0
		melee_area.collision_mask = 2  # игрок
		var shape := CircleShape2D.new()
		shape.radius = melee_range
		var col := CollisionShape2D.new()
		col.shape = shape
		melee_area.add_child(col)
		add_child(melee_area)
		melee_area.body_entered.connect(_on_melee_body)
	if ignore_objects:
		collision_mask = 0  # проходит сквозь стены и объекты
	if show_health_bar:
		_make_hp_bar()


func _make_hp_bar():
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(health_bar_width, health_bar_height)
	hp_bar.position = Vector2(-health_bar_width / 2.0, health_bar_offset)
	hp_bar.min_value = 0.0
	hp_bar.max_value = max(1.0, float(max_hp))
	hp_bar.value = hp
	hp_bar.show_percentage = false
	var sb = StyleBoxFlat.new()
	sb.bg_color = health_bar_color
	hp_bar.add_theme_stylebox_override("fill", sb)
	add_child(hp_bar)


func on_switch_event(num: int, state: bool):
	if num != listener_num:
		return
	if rem_on_switch == 1 and state:
		queue_free()
		return
	if vis_on_switch == 1:
		visible = state
	if act_on_switch == 1:
		is_active = state


func _physics_process(delta):
	if not is_active:
		return
	if knock_timer > 0.0:
		knock_timer -= delta
		velocity = knockback
		if mode == "platformer" and use_gravity and not is_on_floor():
			velocity.y += gravity * delta
		knockback = knockback.move_toward(Vector2.ZERO, 450.0 * delta)
		move_and_slide()
		return
	# Рывок перед ударом: несколько кадров летим с высокой скоростью,
	# урон наносим только когда реально догнали игрока.
	if melee_dashing:
		melee_dash_timer -= delta
		velocity = melee_dash_dir * melee_dash_speed
		if mode == "platformer" and use_gravity and not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		var pl = get_tree().get_nodes_in_group("player")
		if not melee_hit_done and pl.size() > 0:
			var pd: Vector2 = pl[0].global_position - global_position
			if pd.length() < 42.0 and pl[0].has_method("take_damage"):
				melee_hit_done = true
				pl[0].take_damage(melee_damage if melee_damage > 0 else contact_damage)
		if melee_dash_timer <= 0.0:
			melee_dashing = false
		return

	age += delta
	shoot_timer -= delta
	contact_timer -= delta

	var players = get_tree().get_nodes_in_group("player")
	var player = players.front() if players.size() > 0 else null

	# Рукопашный рывок: резко сближаемся и бьём, затем кулдаун.
	melee_timer -= delta
	if melee_enabled and melee_timer <= 0.0 and player != null:
		var to_player: Vector2 = player.global_position - global_position
		if to_player.length() < melee_range:
			_do_melee_lunge(to_player)
			return

	if mode == "shooter":
		_shooter_move(player)
	else:
		_generic_move(delta, player)

	_try_shoot(player)
	_check_contact()


func _on_melee_body(body):
	if not is_active or melee_enabled == false or melee_timer > 0.0:
		return
	if not body.is_in_group("player"):
		return
	var to_player: Vector2 = body.global_position - global_position
	_do_melee_lunge(to_player)


func _do_melee_lunge(to_player: Vector2):
	if melee_timer > 0.0 or melee_dashing:
		return
	melee_timer = melee_cooldown
	# Резко ускоряемся ВПЕРЁД, урон будет при сближении в течение рывка.
	melee_dashing = true
	melee_dash_timer = melee_dash_time
	melee_dash_dir = to_player.normalized()
	melee_hit_done = false
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = melee_dash_dir.x < 0


func _apply_knock(delta: float):
	if knockback.length() > 0.5:
		velocity += knockback
		knockback = knockback.move_toward(Vector2.ZERO, 380.0 * delta)


func _shooter_move(player):
	# Траектории скроллер-шутера: 0 - статика, 1 - синус X, 2 - синус Y,
	# 3 - круг, 4 - босс (медленно следует за игроком по вертикали).
	var drift := -speed * 0.15
	if move_shape == 0:
		velocity = Vector2.ZERO
	elif move_shape == 1:
		velocity = Vector2(drift, cos(age * 1.4) * speed * 0.3)
	elif move_shape == 2:
		velocity = Vector2(drift * 0.2, sin(age * 1.4) * speed * 0.5)
	elif move_shape == 3:
		velocity = Vector2(drift * 0.3 + cos(age) * speed * 0.25, sin(age) * speed * 0.4)
	elif move_shape == 4:
		var target_y = origin.y
		if player != null and turn_to_player == 1:
			target_y = player.global_position.y
		velocity = Vector2(drift * 0.2, clamp((target_y - global_position.y) * 0.6, -speed * 0.3, speed * 0.3))
	else:
		velocity = Vector2(drift, 0)
	_apply_knock(get_physics_process_delta_time())
	if ignore_objects:
		position += velocity * get_physics_process_delta_time()
	else:
		move_and_slide()
	if has_node("Sprite2D") and player != null:
		$Sprite2D.flip_h = player.global_position.x < global_position.x


func _generic_move(delta, player):
	var v := Vector2.ZERO
	if towards_player == 1 and player != null:
		var d = player.global_position - global_position
		if mode == "platformer":
			v = Vector2(sign(d.x), 0) * speed
		else:
			v = d.normalized() * speed if d.length() > 2.0 else Vector2.ZERO
	elif random_direction == 1 or move_dir_mode == 3:
		random_timer -= delta
		if random_timer <= 0.0:
			random_timer = randf_range(0.8, 2.2)
			move_vec = Vector2.RIGHT.rotated(randf() * TAU)
		v = move_vec * speed
	elif move_dir_mode == 1 or move_dir_mode == 2:
		# 1 - строго влево, 2 - строго вправо (отскок от стены разворачивает).
		if abs(move_vec.x) < 0.1:
			move_vec = Vector2.LEFT if move_dir_mode == 1 else Vector2.RIGHT
		v = move_vec * speed
		dir = 1 if move_vec.x > 0 else -1
	elif move_dir_mode == 0:
		v = Vector2.ZERO

	if ignore_objects:
		velocity = v
		_apply_knock(delta)
		position += velocity * delta
	else:
		if mode == "platformer":
			velocity.x = v.x
			if use_gravity and not is_on_floor():
				velocity.y += gravity * delta
		else:
			velocity.x = v.x
			velocity.y = v.y
		_apply_knock(delta)
		move_and_slide()
		if is_on_wall():
			dir *= -1
			move_vec = -move_vec

	if has_node("Sprite2D") and abs(v.x) > 1.0:
		# Спрайты в оригинале нарисованы лицом вправо — mirrored при движении влево.
		$Sprite2D.flip_h = v.x < 0


func _try_shoot(player):
	if not can_shoot or shoot_timer > 0.0:
		return
	var count := 0
	for b in get_tree().get_nodes_in_group("bullets"):
		if b.get("owner_id") == gc_id:
			count += 1
	if count >= max(1, bullet_max_count):
		return

	var aim := Vector2.ZERO
	if shoot_dir == 1:
		aim = Vector2.LEFT
	elif shoot_dir == 2:
		aim = Vector2.RIGHT
	elif shoot_dir == 3:
		aim = Vector2.DOWN
	elif shoot_dir == 4:
		aim = Vector2.UP
	elif turn_to_player == 1 and player != null:
		var d = player.global_position - global_position
		aim = d.normalized() if d.length() > 0.01 else Vector2.DOWN
	elif speed > 0.0 and abs(velocity.x) > 1.0:
		aim = Vector2(sign(velocity.x), 0)
	else:
		aim = Vector2.DOWN

	shoot_timer = max(0.1, shoot_interval)
	var b = Area2D.new()
	b.set_script(load("res://scripts/entities/bullet.gd"))
	b.team = "enemy"
	b.owner_ref = self
	b.owner_id = gc_id
	b.damage = bullet_damage
	b.lifetime = bullet_lifetime
	b.velocity = aim * bullet_speed
	b.global_position = global_position + aim * 20.0
	b.rotation = aim.angle()

	if bullet_tex != null:
		var spr = Sprite2D.new()
		spr.texture = bullet_tex
		spr.centered = true
		b.add_child(spr)

	var col = CollisionShape2D.new()
	var sh = RectangleShape2D.new()
	sh.size = bullet_shape
	col.shape = sh
	b.add_child(col)
	get_parent().add_child(b)


func _check_contact():
	if contact_damage <= 0 or contact_timer > 0.0:
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	if global_position.distance_to(player.global_position) < 42.0 and player.has_method("take_damage"):
		player.take_damage(contact_damage)
		contact_timer = 0.6


func take_damage(amount: int, _from_pos = null):
	if not is_active:
		return
	if not infinite_health:
		hp -= amount
	var away := Vector2.LEFT
	if _from_pos != null:
		var d: Vector2 = global_position - (_from_pos as Vector2)
		if d.length() > 0.01:
			away = d.normalized()
	elif abs(velocity.x) > 1.0:
		away = Vector2(-sign(velocity.x), 0.0)
	knockback = away * 220.0
	knock_timer = 0.16
	if hp_bar != null:
		hp_bar.value = max(0, hp)
	is_aggro = true
	if tex_hit != null and has_node("Sprite2D"):
		var spr = $Sprite2D
		var old_tex = spr.texture
		var old_frames = spr.hframes
		spr.texture = tex_hit
		spr.hframes = max(1, frames_hit)
		spr.frame = 0
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(spr):
			spr.texture = old_tex
			spr.hframes = old_frames
	else:
		modulate = Color(0.894, 0.361, 0.373, 1)
		await get_tree().create_timer(0.1).timeout
		modulate = Color(0.961, 0.969, 0.980, 1)
	if not infinite_health and hp <= 0:
		if death_switch > 0:
			GameState.trigger_switch(death_switch, 1)
		if gc_id != "":
			GameState.mark_cleared(gc_id)
		if boss and phase == 0:
			var clone = duplicate()
			clone.phase = 1
			clone.hp = max_hp
			clone.start_active = true
			get_parent().add_child(clone)
			clone.global_position = global_position + Vector2(0.0, -180.0)
		queue_free()
