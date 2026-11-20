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
## Показывать ли брызги крови при ранении игрока.
@export var use_blood_particles: bool = true

@export_group("Приседание и кувырок")
## Скорость при приседании (для будущей анимации/хитбокса).
@export var crouch_speed_multiplier: float = 0.35
@export var roll_speed: float = 480.0
@export var roll_time: float = 0.28
@export var roll_cooldown: float = 0.45
@export var roll_invulnerable: bool = true
## Во время кувырка неуязвимость действует столько секунд
## (0 = весь кувырок).
@export var roll_invuln_time: float = 0.0
## Спрайты можно поставить позже — пока просто переключаются состояния.
@export var tex_crouch: Texture2D
@export var frames_crouch: int = 1
@export var tex_roll: Texture2D
@export var frames_roll: int = 1
## Высота коллизии при приседании/кувырке в долях от обычной.
## 0.6 => на 40% ниже, низ коллизии остаётся на месте.
@export var crouch_collision_ratio: float = 0.62
@export var roll_collision_ratio: float = 0.55
## Дополнительно «прижать» низ коллизии к земле, пикселей.
@export var collision_bottom_offset: float = 2.0

# --- Смерть ---
@export_group("Смерть")
## Горизонтальная скорость "смешного" отлёта после смерти.
@export var death_launch_speed: float = 520.0
## Сила подброса вверх при смерти (только платформер).
@export var death_launch_up: float = 420.0
## Скорость вращения спрайта при смерти, градусов в секунду.
@export var death_spin_speed: float = 900.0
## Множитель гравитации во время смерти (1 = обычная).
@export var death_gravity_scale: float = 1.0
## Границы скейла силы отлёта от урона (чтобы не улетать в космос).
@export var death_launch_min_scale: float = 0.75
@export var death_launch_max_scale: float = 1.35

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

var is_crouching: bool = false
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_cooldown_timer: float = 0.0
var roll_dir: int = 1
var roll_invuln_timer: float = 0.0
var _base_shape_size: Vector2 = Vector2.ZERO
var _base_shape_pos: Vector2 = Vector2.ZERO
var _body_shape: RectangleShape2D = null
var _body_col: CollisionShape2D = null

var _last_hit_from = null
var _death_spin_dir: float = 1.0
var _death_spin: float = 900.0
var _death_launched: bool = false


func _ready():
	add_to_group("player")
	# Слои: 1 — мир/блоки, 2 — актёры, 3 — толкаемые объекты.
	# Игрок не должен физически толкаться с врагами, но должен стоять на блоках
	# и толкать ящики.
	collision_layer = 2
	collision_mask = 5  # 1 | 4: блоки + ящики, НЕ актёры
	if has_node("CollisionShape2D") and $CollisionShape2D.shape is RectangleShape2D:
		_body_col = $CollisionShape2D
		_body_shape = _body_col.shape.duplicate() as RectangleShape2D
		_body_col.shape = _body_shape
		_base_shape_size = _body_shape.size
		_base_shape_pos = _body_col.position


func _apply_body_collision(ratio: float):
	if _body_shape == null or _base_shape_size.y <= 0.0:
		return
	var h := maxf(4.0, _base_shape_size.y * clampf(ratio, 0.2, 1.0))
	if absf(_body_shape.size.y - h) < 0.01:
		return
	_body_shape.size.y = h
	# Нижняя граница остаётся на земле (+ небольшой визуальный «прижим»).
	_body_col.position.y = _base_shape_pos.y + (_base_shape_size.y - h) * 0.5 + collision_bottom_offset


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
	if is_dead:
		_process_death(delta)
		return
	if GameState.dialogue_active:
		velocity = Vector2.ZERO
		return
	# Отскакивание: на короткое время берём управление горизонталью.
	# Вертикаль не перезаписываем knockback'ом — иначе игрок может улететь вверх.
	if knock_timer > 0.0:
		knock_timer -= delta
		if mode == "platformer":
			velocity.x = knockback.x
			if not is_on_floor():
				velocity.y += gravity * delta
			else:
				velocity.y = 0.0
		else:
			velocity = knockback
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
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("shoot"):
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
		if Input.is_action_pressed("shoot") and not is_attacking:
			_shoot(false)
		elif Input.is_action_pressed("melee") and not is_attacking:
			_melee(false)
		if not is_attacking:
			if rdir.length() > 0:
				_set_anim(tex_move, frames_move)
			else:
				_set_anim(tex_idle, frames_idle)
		_apply_knock(delta)
		move_and_slide()
		return

	# 3. Платформер: гравитация, прыжки, приседание, кувырок, атаки
	var in_air = not is_on_floor()
	if in_air:
		velocity.y += gravity * delta

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		facing = 1 if direction > 0 else -1

	roll_cooldown_timer = maxf(0.0, roll_cooldown_timer - delta)
	roll_invuln_timer = maxf(0.0, roll_invuln_timer - delta)
	if is_rolling:
		_apply_body_collision(roll_collision_ratio)
	elif is_crouching:
		_apply_body_collision(crouch_collision_ratio)
	else:
		_apply_body_collision(1.0)

	# Кувырок: вниз + влево/вправо (на земле, с кулдауном).
	if is_rolling:
		roll_timer -= delta
		velocity.x = roll_dir * roll_speed
		if not in_air:
			velocity.y = 0.0
		_set_anim(tex_roll, frames_roll)
		if roll_timer <= 0.0:
			is_rolling = false
		_apply_knock(delta)
		move_and_slide()
		return

	if (not in_air and roll_cooldown_timer <= 0.0 and not is_attacking
			and Input.is_action_pressed("ui_down") and direction != 0):
		is_rolling = true
		is_crouching = false
		roll_dir = 1 if direction > 0 else -1
		roll_timer = roll_time
		roll_cooldown_timer = roll_cooldown
		roll_invuln_timer = roll_invuln_time if roll_invuln_time > 0.0 else roll_time
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = roll_dir < 0
		GameEvents.request_burst("dust",
			global_position + body_center + Vector2(float(roll_dir) * 24.0, 0.0),
			Color(0.75, 0.72, 0.62, 1.0), Vector2(-float(roll_dir), 0.0))
		_set_anim(tex_roll, frames_roll)
		velocity.x = roll_dir * roll_speed
		_apply_knock(delta)
		move_and_slide()
		return

	# Приседание: просто зажатый вниз без направления.
	is_crouching = not in_air and Input.is_action_pressed("ui_down") and not is_attacking

	if not is_crouching and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")) and not in_air:
		velocity.y = jump_force

	if direction != 0:
		var move_speed := speed * (crouch_speed_multiplier if is_crouching else 1.0)
		velocity.x = direction * move_speed
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = facing < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	if Input.is_action_pressed("shoot") and not is_attacking:
		_shoot(in_air)
	elif Input.is_action_pressed("melee") and not is_attacking:
		_melee(in_air)

	if not is_attacking:
		if is_crouching and tex_crouch != null:
			_set_anim(tex_crouch, frames_crouch)
		elif in_air and tex_jump != null:
			_set_anim(tex_jump, frames_jump, jump_freeze)
		elif direction != 0 and tex_move != null:
			_set_anim(tex_move, frames_move)
		else:
			_set_anim(tex_idle, frames_idle)

	_apply_knock(delta)
	move_and_slide()


func _apply_knock(delta: float):
	if knockback.length() > 0.5:
		if mode == "platformer":
			# В платформере отброс только горизонтальный, иначе прыжок/гравитация ломаются.
			velocity.x += knockback.x
		else:
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
	# Игрок атакует какашками — вспышка у дула тоже какашечная.
	GameEvents.request_burst("poop", b.global_position, Color(0.45, 0.30, 0.16, 1.0), aim)

	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(self):
		is_attacking = false


func _melee(in_air: bool):
	is_attacking = true
	if in_air and tex_melee_air != null:
		_set_anim(tex_melee_air, frames_melee_air, true)  # заморозить последний кадр удара в прыжке
	elif tex_melee != null:
		_set_anim(tex_melee, frames_melee)

	var hit_any := false
	for body in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(body.global_position) < 70.0 and body.has_method("take_damage"):
			body.take_damage(melee_damage, global_position)
			# Кровь создаёт сама цель в take_damage() — там учитывается её флаг
			# use_blood_particles и направление от удара.
			hit_any = true
	for area in get_tree().get_nodes_in_group("switch_listeners"):
		if global_position.distance_to(area.global_position) < 70.0 and area.has_method("on_melee_hit"):
			area.on_melee_hit()
	for body in get_tree().get_nodes_in_group("destroyables"):
		if global_position.distance_to(body.global_position) < 70.0 and body.has_method("take_damage"):
			body.take_damage(melee_damage, global_position)
			hit_any = true
	if hit_any:
		GameEvents.request_hit_stop("hit")

	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(self):
		is_attacking = false


func heal(amount: int):
	GameState.hp = min(max_hp, GameState.hp + amount)


func _shake_camera(preset: String, amount: int = 0) -> void:
	GameEvents.request_shake(preset, maxf(0.7, float(amount) / 25.0))


func take_damage(amount: int, _from_pos = null):
	if is_dead or invuln_timer > 0.0:
		return
	if is_rolling and roll_invulnerable and roll_invuln_timer > 0.0:
		return
		return
	_last_hit_from = _from_pos
	invuln_timer = hurt_invuln_time
	_shake_camera("hit", amount)
	GameEvents.request_hit_stop("hit" if amount >= 15 else "light")
	# Слабое короткое отталкивание от источника урона.
	var away := Vector2(-float(facing), 0.0)
	if _from_pos is Vector2:
		var d: Vector2 = global_position - (_from_pos as Vector2)
		if d.length() > 0.01:
			away = d.normalized()
	if use_blood_particles:
		GameEvents.request_burst("blood", global_position, Color(0.78, 0.10, 0.12, 1.0), away)
	if mode == "platformer":
		# По Y не отбрасываем: иначе при попадании снизу/сбоку можно улететь в космос.
		away.y = 0.0
		if away.length() < 0.01:
			away = Vector2(-float(facing), 0.0)
		away = away.normalized()
	knockback = away * 260.0
	knock_timer = 0.18
	GameState.hp = max(0, GameState.hp - amount)
	if GameState.hp <= 0:
		_die(amount)
		return
	if tex_hit != null:
		hurt_timer = hurt_invuln_time
		_set_anim(tex_hit, frames_hit)


func _die(amount: int = 0):
	if is_dead:
		return
	is_dead = true
	is_rolling = false
	is_crouching = false
	GameEvents.request_burst("death", global_position, Color(1.0, 0.36, 0.36, 1.0))
	_shake_camera("death")
	hurt_timer = 0.0
	if tex_dead != null:
		_set_anim(tex_dead, frames_dead, true)  # последний кадр анимации смерти
	elif tex_hit != null:
		_set_anim(tex_hit, frames_hit, true)
	_start_death_launch(amount)
	# Экран проигрыша появляется не сразу, а после анимации смерти.
	await get_tree().create_timer(death_delay).timeout
	if is_instance_valid(self):
		GameState.kill_player()


func _start_death_launch(amount: int = 0) -> void:
	# Чем больше урон, тем сильнее отлёт, но с жёстким потолком.
	var damage_scale := clampf(0.75 + float(amount) / maxf(1.0, float(max_hp)) * 1.5,
		death_launch_min_scale, death_launch_max_scale)
	# Направление отлёта — от источника последнего урона, иначе назад от взгляда.
	var away := Vector2(-float(facing), 0.0)
	if _last_hit_from is Vector2:
		var d: Vector2 = global_position - (_last_hit_from as Vector2)
		if d.length() > 0.01:
			away = d.normalized()
	if mode == "platformer":
		# В платформере — сильный горизонтальный отлёт + подброс вверх.
		var dir_x := signf(away.x)
		if absf(dir_x) < 0.01:
			dir_x = -float(facing)
		velocity = Vector2(dir_x * death_launch_speed * damage_scale, -death_launch_up * damage_scale)
	else:
		velocity = away.normalized() * death_launch_speed * damage_scale
	# Крутим в сторону, противоположную полёту — так смешнее.
	_death_spin_dir = -1.0 if velocity.x >= 0.0 else 1.0
	_death_spin = death_spin_speed * randf_range(0.85, 1.25) * clampf(damage_scale, 0.85, 1.15)
	_prepare_death_spin()
	_death_launched = true


func _prepare_death_spin() -> void:
	# Sprite2D у игрока стоит centered = false, поэтому вращение шло бы вокруг
	# верхнего левого угла. Переводим его в centered и ставим в центр тела —
	# картинка не смещается, но крутится вокруг себя.
	if not has_node("Sprite2D"):
		return
	var spr: Sprite2D = $Sprite2D
	var pivot: Vector2 = body_center
	if pivot == Vector2.ZERO:
		var frame_size := Vector2(79.0, 95.0)
		if spr.texture != null:
			frame_size = spr.texture.get_size() / Vector2(maxi(1, spr.hframes), maxi(1, spr.vframes))
		pivot = frame_size * 0.5
	spr.centered = true
	spr.position = pivot


func _process_death(delta: float) -> void:
	if not _death_launched:
		return
	if mode == "platformer":
		velocity.y += gravity * delta * death_gravity_scale
	# Постепенно гасим горизонталь, чтобы не улетал бесконечно по земле.
	velocity.x = move_toward(velocity.x, 0.0, 140.0 * delta)
	var fall_speed: float = velocity.y
	move_and_slide()
	if mode == "platformer" and is_on_floor():
		# Небольшой "тряпичный" отскок от пола, потом быстро затухаем.
		if fall_speed > 160.0:
			velocity.y = -fall_speed * 0.42
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_death_spin = move_toward(_death_spin, 0.0, 700.0 * delta)
	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		spr.rotation += deg_to_rad(_death_spin) * delta * _death_spin_dir
