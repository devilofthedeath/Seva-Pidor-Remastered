extends CharacterBody2D

# --- Режим и движение ---
@export var mode: String = "platformer"  # platformer / rpg / shooter
@export var speed: float = 300.0
@export var jump_force: float = -520.0

# --- Стрельба (значения берутся из .obj) ---
@export var has_gun: bool = true
@export var shoot_dir: int = 0            # 0 - по направлению движения, 1 - влево, 2 - вправо, 3 - 4 стороны
@export var shoot_angle: float = -1.0     # >= 0 - явный угол в градусах (0 = вправо), перекрывает shoot_dir
@export var bullet_speed: float = 420.0
@export var bullet_damage: int = 15
@export var bullet_max_count: int = 1
@export var bullet_lifetime: float = 2.0
@export var shoot_cooldown: float = 0.18
@export var bullet_offset: Vector2 = Vector2(20, 0)
@export var bullet_shape: Vector2 = Vector2(12, 8)
@export var body_center: Vector2 = Vector2(0, 0)
@export var bullet_owner_id: String = "player"
@export var bullet_in_air: bool = false
@export var melee_damage: int = 10

# --- Здоровье ---
@export var max_hp: int = 100
@export var invuln_time: float = 0.7

# --- Анимации ---
@export var tex_idle: Texture2D
@export var frames_idle: int = 1
@export var tex_move: Texture2D
@export var frames_move: int = 1
@export var tex_jump: Texture2D
@export var frames_jump: int = 1
@export var tex_shoot: Texture2D
@export var frames_shoot: int = 1
@export var tex_shoot_air: Texture2D
@export var frames_shoot_air: int = 1
@export var tex_melee: Texture2D
@export var frames_melee: int = 1
@export var tex_melee_air: Texture2D
@export var frames_melee_air: int = 1
@export var tex_bullet: Texture2D
@export var tex_hit: Texture2D
@export var frames_hit: int = 1
@export var tex_dead: Texture2D
@export var frames_dead: int = 1
@export var hurt_invuln_time: float = 0.6
@export var death_delay: float = 2.0
@export var jump_freeze: bool = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing: int = 1
var is_attacking: bool = false
var is_dead: bool = false
var aim_dir: Vector2 = Vector2.RIGHT
var shoot_timer: float = 0.0
var invuln_timer: float = 0.0
var hurt_timer: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var knock_timer: float = 0.0


func _ready():
	add_to_group("player")
	# Слои: 1 — мир/блоки, 2 — актёры, 3 — толкаемые объекты.
	# Игрок не должен физически толкаться с врагами, но должен стоять на блоках
	# и толкать ящики.
	collision_layer = 2
	collision_mask = 5  # 1 | 4: блоки + ящики, НЕ актёры


func _set_anim(tex: Texture2D, f_count: int, freeze_last: bool = false):
	# Пока идёт анимация урона — не перебиваем её обычными idle/move.
	if hurt_timer > 0.0 and tex != tex_hit:
		return
	if tex == null or not has_node("Sprite2D"):
		return
	var spr = $Sprite2D
	if spr.texture != tex:
		spr.texture = tex
		spr.hframes = max(1, f_count)
		spr.frame = 0
	spr.freeze_last = freeze_last


func _aim_vector() -> Vector2:
	# Направление берётся из shooting_direction оригинального .obj:
	# 1 - влево, 2 - вправо, 3 - вниз, 4 - вверх, 0 - на игрока/по взгляду.
	# У topview-игрока стоит 3 (мина вниз), у скроллер-шутера 2 (вправо).
	if shoot_angle >= 0.0:
		return Vector2.RIGHT.rotated(deg_to_rad(shoot_angle))
	if shoot_dir == 1:
		return Vector2.LEFT
	if shoot_dir == 2:
		return Vector2.RIGHT
	if shoot_dir == 3:
		return Vector2.DOWN
	if shoot_dir == 4:
		return Vector2.UP
	return Vector2(facing, 0)


func _active_bullets() -> int:
	var count := 0
	for b in get_tree().get_nodes_in_group("bullets"):
		if b.get("owner_id") == bullet_owner_id:
			count += 1
	return count


func _physics_process(delta):
	if GameState.dialogue_active or is_dead:
		velocity = Vector2.ZERO
		return
	# Отскакивание: на короткое время полностью берём управление движением.
	if knock_timer > 0.0:
		knock_timer -= delta
		velocity = knockback
		if mode == "platformer":
			velocity.y += gravity * delta
		knockback = knockback.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		return
	if global_position.y > GameState.level_bottom:
		_die()
		return
	shoot_timer = max(0.0, shoot_timer - delta)
	invuln_timer = max(0.0, invuln_timer - delta)
	hurt_timer = max(0.0, hurt_timer - delta)
	if invuln_timer > 0.0 and has_node("Sprite2D"):
		$Sprite2D.visible = fmod(invuln_timer, 0.12) > 0.06
	else:
		if has_node("Sprite2D"):
			$Sprite2D.visible = true

	# 1. Скроллер-шутер: постоянный полёт вправо + маневр + стрельба
	if mode == "shooter":
		var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity.x = speed * 0.85 + dir.x * (speed * 0.5)
		velocity.y = dir.y * speed
		if dir != Vector2.ZERO:
			aim_dir = dir
		if dir.x != 0:
			facing = 1 if dir.x > 0 else -1
		if Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_CTRL):
			if not is_attacking:
				_shoot(false)
		_apply_knock(delta)
		move_and_slide()
		return

	# 2. RPG / вид сверху: свободное движение по XY + 4 направления стрельбы
	if mode == "rpg":
		var rdir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = rdir * speed
		if rdir.x != 0:
			facing = 1 if rdir.x > 0 else -1
			aim_dir = Vector2.RIGHT if rdir.x > 0 else Vector2.LEFT
		elif rdir.y != 0:
			aim_dir = Vector2.DOWN if rdir.y > 0 else Vector2.UP
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = facing < 0
		if (Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_CTRL)) and not is_attacking:
			_shoot(false)
		elif (Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_SHIFT)) and not is_attacking:
			_melee(false)
		if not is_attacking:
			if rdir.length() > 0:
				_set_anim(tex_move, frames_move)
			else:
				_set_anim(tex_idle, frames_idle)
		_apply_knock(delta)
		move_and_slide()
		return

	# 3. Платформер: гравитация, прыжки, наземные и воздушные атаки
	var in_air = not is_on_floor()
	if in_air:
		velocity.y += gravity * delta

	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")) and not in_air:
		velocity.y = jump_force

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * speed
		facing = 1 if direction > 0 else -1
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = facing < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	if (Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_CTRL)) and not is_attacking:
		_shoot(in_air)
	elif (Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_SHIFT)) and not is_attacking:
		_melee(in_air)

	if not is_attacking:
		if in_air and tex_jump != null:
			_set_anim(tex_jump, frames_jump, jump_freeze)
		elif direction != 0 and tex_move != null:
			_set_anim(tex_move, frames_move)
		else:
			_set_anim(tex_idle, frames_idle)

	_apply_knock(delta)
	move_and_slide()


func _apply_knock(delta: float):
	if knockback.length() > 0.5:
		velocity += knockback
		knockback = knockback.move_toward(Vector2.ZERO, 420.0 * delta)


func _shoot(in_air: bool):
	if not has_gun or is_attacking or shoot_timer > 0.0:
		return
	if in_air and not bullet_in_air:
		return
	if _active_bullets() >= max(1, bullet_max_count):
		return

	shoot_timer = shoot_cooldown
	is_attacking = true
	if in_air and tex_shoot_air != null:
		_set_anim(tex_shoot_air, frames_shoot_air)
	elif tex_shoot != null:
		_set_anim(tex_shoot, frames_shoot)

	var aim: Vector2 = _aim_vector().normalized()
	var off := bullet_offset
	if bullet_speed > 0.0:
		off.x *= sign(aim.x)
	else:
		# Неподвижная мина — под центром тела, а не со смещением вбок.
		off += Vector2.ZERO #body_center
	var b = Area2D.new()
	b.set_script(load("res://scripts/entities/bullet.gd"))
	b.team = "player"
	b.owner_ref = self
	b.owner_id = bullet_owner_id
	b.damage = bullet_damage
	b.lifetime = bullet_lifetime
	b.velocity = aim * bullet_speed
	if bullet_speed > 0.0:
		# Дуло у края спрайта в сторону выстрела, а не сверху головы.
		var muzzle := body_center + Vector2(aim.x * body_center.x, aim.y * body_center.y) * 0.9
		b.global_position = global_position + muzzle
	else:
		b.global_position = global_position + body_center + off
	b.rotation = aim.angle() if bullet_speed > 0.0 else 0.0

	if tex_bullet != null:
		var spr = Sprite2D.new()
		spr.texture = tex_bullet
		spr.centered = true
		b.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = bullet_shape
	col.shape = shape
	b.add_child(col)
	get_parent().add_child(b)

	await get_tree().create_timer(0.2).timeout
	is_attacking = false


func _melee(in_air: bool):
	is_attacking = true
	if in_air and tex_melee_air != null:
		_set_anim(tex_melee_air, frames_melee_air, true)  # заморозить последний кадр удара в прыжке
	elif tex_melee != null:
		_set_anim(tex_melee, frames_melee)

	for body in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(body.global_position) < 70.0 and body.has_method("take_damage"):
			body.take_damage(melee_damage)
	for area in get_tree().get_nodes_in_group("switch_listeners"):
		if global_position.distance_to(area.global_position) < 70.0 and area.has_method("on_melee_hit"):
			area.on_melee_hit()
	for body in get_tree().get_nodes_in_group("destroyables"):
		if global_position.distance_to(body.global_position) < 70.0 and body.has_method("take_damage"):
			body.take_damage(melee_damage)

	await get_tree().create_timer(0.2).timeout
	is_attacking = false


func heal(amount: int):
	GameState.hp = min(max_hp, GameState.hp + amount)
	get_tree().call_group("hud_health", "update_hp", GameState.hp, max_hp)


func take_damage(amount: int, _from_pos = null):
	if is_dead or invuln_timer > 0.0:
		return
	invuln_timer = hurt_invuln_time
	# Слабое короткое отталкивание от источника урона.
	var away := Vector2(-float(facing), 0.0)
	if _from_pos != null:
		var d: Vector2 = global_position - (_from_pos as Vector2)
		if d.length() > 0.01:
			away = d.normalized()
	knockback = away * 260.0
	knock_timer = 0.18
	GameState.hp = max(0, GameState.hp - amount)
	get_tree().call_group("hud_health", "update_hp", GameState.hp, max_hp)
	if GameState.hp <= 0:
		_die()
		return
	if tex_hit != null:
		hurt_timer = hurt_invuln_time
		_set_anim(tex_hit, frames_hit)


func _die():
	is_dead = true
	hurt_timer = 0.0
	velocity = Vector2.ZERO
	if tex_dead != null:
		_set_anim(tex_dead, frames_dead, true)  # последний кадр анимации смерти
	elif tex_hit != null:
		_set_anim(tex_hit, frames_hit, true)
	# Экран проигрыша появляется не сразу, а после анимации смерти.
	await get_tree().create_timer(death_delay).timeout
	GameState.kill_player()
