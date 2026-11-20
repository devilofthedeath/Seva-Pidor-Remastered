extends CharacterBody2D
## Универсальный враг для всех режимов игры (платформер / топвью / скроллер).
## Всё, что раньше было «магическими числами», теперь настраивается в инспекторе.

signal hp_changed(current: int, maximum: int)
signal died(enemy: CharacterBody2D)
signal aggro_changed(is_aggro: bool)

const BULLET_SCRIPT: Script = preload("res://scripts/entities/bullet.gd")

@export_group("Профиль")
## Профиль из res://resources/enemies/*.tres. Если не задан — используются
## значения полей ниже (старые сцены работают именно так).
@export var profile: EnemyProfile
@export var apply_profile_on_ready: bool = true

@export_group("Основное")
@export_enum("platformer", "topview", "shooter") var mode: String = "platformer"
@export var speed: float = 90.0
@export var max_hp: int = 30
@export var hp: int = 30
@export var infinite_health: bool = false
@export var gc_id: String = ""
@export var boss: bool = false
@export var phase: int = 0
@export var start_visible: bool = true
@export var start_active: bool = true

@export_group("Контактный урон")
@export var contact_damage_enabled: bool = true
@export var contact_damage: int = 10
## Радиус, в котором контактный урон срабатывает.
@export var contact_range: float = 42.0
@export var contact_cooldown: float = 0.6

@export_group("Движение")
@export var use_gravity: bool = true
## Множитель гравитации проекта (1.0 = как в Project Settings).
@export var gravity_scale: float = 1.0
@export_enum("None", "Left", "Right", "Random") var move_dir_mode: int = 1
@export_enum("Static", "Sine X", "Sine Y", "Circle", "Boss follow") var move_shape: int = 0
@export var towards_player: int = 0
@export var random_direction: int = 0
@export var ignore_objects: bool = false
@export var turn_to_player: int = 0
## Случайная смена направления каждые min..max секунд.
@export var random_turn_min: float = 0.8
@export var random_turn_max: float = 2.2

@export_group("Агро")
## Враг «просыпается», когда игрок близко (0 = не просыпаться).
@export var aggro_radius: float = 0.0
@export var aggro_on_damage: bool = true
## Множитель скорости после пробуждения (1.0 = без изменений).
@export var aggro_speed_multiplier: float = 1.0

@export_group("Получение урона")
@export var receive_knockback: bool = true
@export var knockback_strength: float = 220.0
## Фиксированный маленький подскок при ранении (не складывается от пуль).
@export var knockback_hop: float = 95.0
@export var knockback_time: float = 0.16
## Затухание отброса: при столкновении/полёте и при обычном движении.
@export var knockback_decay: float = 450.0
@export var knockback_decay_walking: float = 380.0
@export var tex_hit: Texture2D
@export var frames_hit: int = 1
@export var hit_flash_time: float = 0.15
@export var hit_tint_time: float = 0.1
@export var hit_tint_color: Color = Color(0.894, 0.361, 0.373, 1)
@export var hit_tint_reset: Color = Color(0.961, 0.969, 0.980, 1)
## Показывать ли брызги крови при ранении (можно выключить для «чистых» врагов).
@export var use_blood_particles: bool = true

@export_group("Рукопашная атака")
## Рукопашный рывок (для врагов без пуль).
@export var melee_enabled: bool = true
@export var melee_range: float = 72.0
@export var melee_lunge_speed: float = 300.0
## Сам рывок: скорость и длительность перед ударом.
@export var melee_dash_speed: float = 650.0
@export var melee_dash_time: float = 0.18
@export var melee_hit_radius: float = 42.0
@export var melee_cooldown: float = 1.3
## 0 = использовать contact_damage.
@export var melee_damage: int = 0

@export_group("Стрельба")
@export var can_shoot: bool = false
@export_enum("Auto", "Left", "Right", "Down", "Up") var shoot_dir: int = 0
@export var require_aggro_to_shoot: bool = false
@export var bullet_speed: float = 300.0
@export var bullet_damage: int = 10
@export var bullet_max_count: int = 1
@export var bullet_lifetime: float = 2.0
@export var bullet_spawn_offset: float = 20.0
@export var min_shoot_interval: float = 0.1
## Снарядов за выстрел и разброс между ними (градусы).
@export_range(1, 16, 1) var projectiles_per_shot: int = 1
@export var spread_angle_deg: float = 0.0
@export var shoot_interval: float = 1.0
@export var bullet_tex: Texture2D
@export var bullet_shape: Vector2 = Vector2(10, 8)

@export_group("Прицеливание")
## Auto-направление (shoot_dir = 0) целится в центр тела игрока, а не в его origin.
@export var aim_at_player_center: bool = true
## Неподвижные стрелки разворачивают спрайт к игроку даже без движения.
@export var face_player_when_shooting: bool = true
## Пуля вылетает из центра тела врага, а не из его origin (у SPI-спрайтов это верх головы).
@export var bullet_spawn_from_body_center: bool = true

@export_group("Смерть")
@export var death_switch: int = 0
@export var death_switch_value: int = 1
@export var mark_cleared_on_death: bool = true
## Создавать копию второй фазы после смерти босса.
@export var spawn_phase_clone: bool = true
@export var phase_clone_offset: Vector2 = Vector2(0.0, -180.0)
@export var phase_clone_full_hp: bool = true
@export var shake_on_death: bool = false
@export var death_shake_preset: String = "heavy"
## Смерть-отлёт: враг улетает кувырком и растворяется фейдом.
@export var death_launch_speed: float = 260.0
@export var death_launch_up: float = 180.0
@export var death_spin_speed: float = 720.0
@export var death_launch_gravity_scale: float = 1.0
## Время до полного исчезновения после смерти.
@export var death_fade_time: float = 2.0
## Сколько времени враг остаётся видимым до начала фейда.
@export var death_fade_delay: float = 1.2
## Границы скейла силы отлёта от урона.
@export var death_launch_min_scale: float = 0.75
@export var death_launch_max_scale: float = 1.3

@export_group("Деспавн")
@export var despawn_enabled: bool = false
## 0 = не проверять расстояние от точки появления.
@export var despawn_distance: float = 0.0
## 0 = не проверять время жизни.
@export var max_lifetime: float = 0.0

@export_group("Полоса здоровья")
@export var show_health_bar: bool = false
@export var health_bar_width: int = 40
@export var health_bar_height: int = 6
@export var health_bar_color: Color = Color(0.714, 0.235, 0.208, 1)
@export var health_bar_offset: float = -20.0

@export_group("Переключатели")
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
var is_dying: bool = false
var _death_spin: float = 0.0
var _death_spin_dir: float = 1.0
var _death_launched: bool = false


func _ready():
	if profile != null and apply_profile_on_ready:
		profile.apply_to(self)
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


func _set_aggro(value: bool) -> void:
	if is_aggro == value:
		return
	is_aggro = value
	aggro_changed.emit(is_aggro)


func _effective_speed() -> float:
	return speed * (aggro_speed_multiplier if is_aggro else 1.0)


func _check_despawn() -> bool:
	if not despawn_enabled:
		return false
	if max_lifetime > 0.0 and age >= max_lifetime:
		queue_free()
		return true
	if despawn_distance > 0.0 and global_position.distance_to(origin) > despawn_distance:
		queue_free()
		return true
	return false


func _physics_process(delta):
	if is_dying:
		_process_death(delta)
		return
	if not is_active:
		return
	if _check_despawn():
		return
	if knock_timer > 0.0 and receive_knockback:
		knock_timer -= delta
		if mode == "platformer":
			# Отброс только по горизонтали; по Y работает фиксированный подскок
			# и гравитация, чтобы он не превращался в полёт.
			velocity.x = knockback.x
			velocity.y += gravity * gravity_scale * delta
		else:
			velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, knockback_decay * delta)
		move_and_slide()
		return
	# Рывок перед ударом: несколько кадров летим с высокой скоростью,
	# урон наносим только когда реально догнали игрока.
	if melee_dashing:
		melee_dash_timer -= delta
		velocity = melee_dash_dir * melee_dash_speed
		if mode == "platformer" and use_gravity and not is_on_floor():
			velocity.y += gravity * gravity_scale * delta
		move_and_slide()
		var pl = get_tree().get_nodes_in_group("player")
		if not melee_hit_done and pl.size() > 0:
			var pd: Vector2 = pl[0].global_position - global_position
			if pd.length() < melee_hit_radius and pl[0].has_method("take_damage"):
				melee_hit_done = true
				pl[0].take_damage(melee_damage if melee_damage > 0 else contact_damage, global_position)
		if melee_dash_timer <= 0.0:
			melee_dashing = false
		return

	age += delta
	shoot_timer -= delta
	contact_timer -= delta

	var players = get_tree().get_nodes_in_group("player")
	var player = players.front() if players.size() > 0 else null

	# Пробуждение, когда игрок подошёл близко.
	if aggro_radius > 0.0 and not is_aggro and player != null:
		if global_position.distance_to(player.global_position) <= aggro_radius:
			_set_aggro(true)

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
	if not receive_knockback:
		return
	if knockback.length() > 0.5:
		if mode == "platformer":
			velocity.x += knockback.x
		else:
			velocity += knockback
		knockback = knockback.move_toward(Vector2.ZERO, knockback_decay_walking * delta)


func _shooter_move(player):
	# Траектории скроллер-шутера: 0 - статика, 1 - синус X, 2 - синус Y,
	# 3 - круг, 4 - босс (медленно следует за игроком по вертикали).
	var move_speed := _effective_speed()
	var drift := -move_speed * 0.15
	if move_shape == 0:
		velocity = Vector2.ZERO
	elif move_shape == 1:
		velocity = Vector2(drift, cos(age * 1.4) * move_speed * 0.3)
	elif move_shape == 2:
		velocity = Vector2(drift * 0.2, sin(age * 1.4) * move_speed * 0.5)
	elif move_shape == 3:
		velocity = Vector2(drift * 0.3 + cos(age) * move_speed * 0.25, sin(age) * move_speed * 0.4)
	elif move_shape == 4:
		var target_y = origin.y
		if player != null and turn_to_player == 1:
			target_y = player.global_position.y
		velocity = Vector2(drift * 0.2, clamp((target_y - global_position.y) * 0.6, -move_speed * 0.3, move_speed * 0.3))
	else:
		velocity = Vector2(drift, 0)
	_apply_knock(get_physics_process_delta_time())
	if ignore_objects:
		position += velocity * get_physics_process_delta_time()
	else:
		move_and_slide()
	if has_node("Sprite2D") and player != null and face_player_when_shooting:
		$Sprite2D.flip_h = _body_center(player).x < _body_center(self).x


func _body_center(node: Node2D) -> Vector2:
	if node == null:
		return Vector2.ZERO
	for child in node.get_children():
		if child is CollisionShape2D:
			return (child as CollisionShape2D).global_position
	return node.global_position


func _aim_at_target(player: Node2D) -> Vector2:
	var from := _body_center(self) if aim_at_player_center else global_position
	var to := _body_center(player) if aim_at_player_center else player.global_position
	var d := to - from
	return d.normalized() if d.length() > 0.01 else Vector2.DOWN


func _should_face_player(player: Node2D) -> bool:
	if player == null:
		return false
	return face_player_when_shooting and (turn_to_player == 1 or (can_shoot and shoot_dir == 0))


func _generic_move(delta, player):
	var move_speed := _effective_speed()
	var v := Vector2.ZERO
	if towards_player == 1 and player != null:
		var d = player.global_position - global_position
		if mode == "platformer":
			v = Vector2(sign(d.x), 0) * move_speed
		else:
			v = d.normalized() * move_speed if d.length() > 2.0 else Vector2.ZERO
	elif random_direction == 1 or move_dir_mode == 3:
		random_timer -= delta
		if random_timer <= 0.0:
			random_timer = randf_range(random_turn_min, maxf(random_turn_min, random_turn_max))
			move_vec = Vector2.RIGHT.rotated(randf() * TAU)
		v = move_vec * move_speed
	elif move_dir_mode == 1 or move_dir_mode == 2:
		# 1 - строго влево, 2 - строго вправо (отскок от стены разворачивает).
		if abs(move_vec.x) < 0.1:
			move_vec = Vector2.LEFT if move_dir_mode == 1 else Vector2.RIGHT
		v = move_vec * move_speed
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
				velocity.y += gravity * gravity_scale * delta
		else:
			velocity.x = v.x
			velocity.y = v.y
		_apply_knock(delta)
		move_and_slide()
		if is_on_wall():
			dir *= -1
			move_vec = -move_vec

	if has_node("Sprite2D"):
		if _should_face_player(player):
			# Спрайты в оригинале нарисованы лицом вправо.
			$Sprite2D.flip_h = _body_center(player).x < _body_center(self).x
		elif abs(v.x) > 1.0:
			$Sprite2D.flip_h = v.x < 0


func _try_shoot(player):
	if not can_shoot or shoot_timer > 0.0:
		return
	if require_aggro_to_shoot and not is_aggro and not boss:
		return

	# fallback на instance id: враги без gc_id не должны делить лимит пуль.
	var owner_key := gc_id if gc_id != "" else str(get_instance_id())
	var count := 0
	for b in get_tree().get_nodes_in_group("bullets"):
		if b.get("owner_id") == owner_key:
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
	elif shoot_dir == 0 and player != null:
		aim = _aim_at_target(player)
	elif turn_to_player == 1 and player != null:
		aim = _aim_at_target(player)
	elif _effective_speed() > 0.0 and abs(velocity.x) > 1.0:
		aim = Vector2(sign(velocity.x), 0)
	else:
		aim = Vector2.DOWN

	if has_node("Sprite2D") and (turn_to_player == 1 or _should_face_player(player)) and player != null and abs(aim.x) > 0.01:
		$Sprite2D.flip_h = aim.x < 0.0

	shoot_timer = max(min_shoot_interval, shoot_interval)
	var shots: int = max(1, projectiles_per_shot)
	var spread := deg_to_rad(spread_angle_deg)
	for i in shots:
		var t := 0.0 if shots == 1 else float(i) / float(shots - 1) - 0.5
		_spawn_bullet(aim.rotated(spread * t), owner_key)


func _spawn_bullet(direction: Vector2, owner_key: String) -> void:
	var b = BULLET_SCRIPT.new()
	b.team = "enemy"
	b.owner_ref = self
	b.owner_id = owner_key
	b.damage = bullet_damage
	b.lifetime = bullet_lifetime
	b.velocity = direction * bullet_speed
	var spawn_origin := _body_center(self) if bullet_spawn_from_body_center else global_position
	b.global_position = spawn_origin + direction * bullet_spawn_offset
	b.rotation = direction.angle()

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
	GameEvents.request_burst("muzzle", b.global_position, Color(1.0, 0.62, 0.25, 1.0), direction)


func _check_contact():
	if not contact_damage_enabled or contact_damage <= 0 or contact_timer > 0.0:
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	if global_position.distance_to(player.global_position) < contact_range and player.has_method("take_damage"):
		player.take_damage(contact_damage, global_position)
		contact_timer = contact_cooldown


func take_damage(amount: int, _from_pos = null):
	if not is_active or is_dying:
		return
	if not infinite_health:
		hp -= amount
		if hp <= 0 and not is_dying:
			# Фиксируем смерть сразу, пока идёт хит-флеш: иначе несколько пуль
			# в одном кадре добавляют нокбек и запускают отлёт по несколько раз.
			is_dying = true
			is_active = false
			# Пули и мили больше не должны тратиться на этого врага.
			remove_from_group("enemies")
	hp_changed.emit(hp, max_hp)
	GameEvents.request_hit_stop("light", 0.9)
	if use_blood_particles:
		var blood_dir := Vector2.RIGHT
		if _from_pos is Vector2:
			var bd: Vector2 = global_position - (_from_pos as Vector2)
			if bd.length() > 0.01:
				blood_dir = bd.normalized()
		GameEvents.request_burst("blood", global_position, Color(0.78, 0.10, 0.12, 1.0), blood_dir)

	if aggro_on_damage:
		_set_aggro(true)

	if receive_knockback:
		var away := Vector2.LEFT
		if _from_pos is Vector2:
			var d: Vector2 = global_position - (_from_pos as Vector2)
			if d.length() > 0.01:
				away = d.normalized()
		elif abs(velocity.x) > 1.0:
			away = Vector2(-sign(velocity.x), 0.0)
		if mode == "platformer":
			# Пуля сверху/снизу не должна подбрасывать врага — only X.
			away.y = 0.0
			if away.length() < 0.01:
				away = Vector2.LEFT if dir > 0 else Vector2.RIGHT
			away = away.normalized()
		knockback = away * knockback_strength
		knock_timer = knockback_time
		if mode == "platformer" and knockback_hop > 0.0 and not is_dying:
			# Не складываемся: каждый удар задаёт один и тот же потолок подскока.
			velocity.y = minf(velocity.y, -knockback_hop)

	if hp_bar != null:
		hp_bar.value = max(0, hp)

	if tex_hit != null and has_node("Sprite2D"):
		var spr = $Sprite2D
		var old_tex = spr.texture
		var old_frames = spr.hframes
		spr.texture = tex_hit
		spr.hframes = max(1, frames_hit)
		spr.frame = 0
		await get_tree().create_timer(hit_flash_time).timeout
		if is_instance_valid(spr):
			spr.texture = old_tex
			spr.hframes = old_frames
	else:
		modulate = hit_tint_color
		await get_tree().create_timer(hit_tint_time).timeout
		modulate = hit_tint_reset

	if not infinite_health and hp <= 0:
		GameEvents.request_burst("death" if boss else "hit", global_position, hit_tint_color)
		died.emit(self)
		GameEvents.emit_enemy_died(self)
		GameEvents.request_hit_stop("death" if boss else "heavy")
		if shake_on_death:
			GameEvents.request_shake(death_shake_preset)
		if death_switch > 0:
			RunState.trigger_switch(death_switch, death_switch_value)
		if gc_id != "" and mark_cleared_on_death:
			RunState.mark_cleared(gc_id)
		if boss and phase == 0 and spawn_phase_clone:
			var clone = duplicate()
			clone.phase = 1
			clone.hp = max_hp if phase_clone_full_hp else maxi(1, int(max_hp / 2.0))
			clone.start_active = true
			get_parent().add_child(clone)
			clone.global_position = global_position + phase_clone_offset
			if not clone.is_in_group("enemies"):
				clone.add_to_group("enemies")
			GameEvents.request_burst("muzzle", clone.global_position, Color(1.0, 0.55, 0.85, 1.0))
		_start_enemy_death(amount, _from_pos)


func _start_enemy_death(amount: int, from_pos) -> void:
	if _death_launched:
		return
	_death_launched = true
	is_dying = true
	is_active = false
	# Дохлый враг больше не цель: пули и мили пролетают сквозь него.
	remove_from_group("enemies")
	if hp_bar != null:
		hp_bar.visible = false

	var damage_scale := clampf(0.75 + float(amount) / maxf(1.0, float(max_hp)) * 1.2,
		death_launch_min_scale, death_launch_max_scale)
	var away := Vector2.LEFT
	if from_pos is Vector2:
		var d: Vector2 = global_position - (from_pos as Vector2)
		if d.length() > 0.01:
			away = d.normalized()
	elif absf(velocity.x) > 1.0:
		away = Vector2(-signf(velocity.x), 0.0)

	if mode == "platformer":
		var dir_x := signf(away.x)
		if absf(dir_x) < 0.01:
			dir_x = 1.0 if dir > 0 else -1.0
		velocity = Vector2(dir_x * death_launch_speed * damage_scale, -death_launch_up * damage_scale)
	else:
		velocity = away.normalized() * death_launch_speed * damage_scale

	_death_spin_dir = -1.0 if velocity.x >= 0.0 else 1.0
	_death_spin = death_spin_speed * randf_range(0.85, 1.2) * clampf(damage_scale, 0.85, 1.15)
	_prepare_death_spin()

	# Сначала летим видимыми, потом плавно растворяемся.
	var fade_duration := maxf(0.05, death_fade_time - death_fade_delay)
	var tw := create_tween()
	if death_fade_delay > 0.0:
		tw.tween_interval(death_fade_delay)
	tw.tween_property(self, "modulate:a", 0.0, fade_duration)
	await get_tree().create_timer(death_fade_time).timeout
	if is_instance_valid(self):
		queue_free()


func _prepare_death_spin() -> void:
	# Спрайты врагов тоже centered = false: вращаем вокруг центра кадра,
	# иначе кувырок выглядит как полёт вокруг верхнего левого угла.
	if not has_node("Sprite2D"):
		return
	var spr: Sprite2D = $Sprite2D
	if spr.texture == null:
		return
	var frame_size: Vector2 = spr.texture.get_size() / Vector2(maxi(1, spr.hframes), maxi(1, spr.vframes))
	spr.centered = true
	spr.position = frame_size * 0.5


func _process_death(delta: float) -> void:
	if not _death_launched:
		return
	if mode == "platformer":
		# Гравитация при смерти работает всегда, даже если у врага use_gravity = false.
		# Иначе он летит вверх вечно и улетает в стратосферу.
		velocity.y += gravity * gravity_scale * death_launch_gravity_scale * delta
		velocity.x = move_toward(velocity.x, 0.0, 160.0 * delta)
	else:
		# В топдауне просто гасим скорость, чтобы не улетел за экран за 2 секунды.
		velocity = velocity.move_toward(Vector2.ZERO, 220.0 * delta)
	move_and_slide()
	if mode == "platformer" and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		_death_spin = move_toward(_death_spin, 0.0, 260.0 * delta)
	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		spr.rotation += deg_to_rad(_death_spin) * delta * _death_spin_dir
