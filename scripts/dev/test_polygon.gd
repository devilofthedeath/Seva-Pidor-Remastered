extends Node2D
## Тестовый полигон: 4 арены в одной сцене.
## 1 — платформер, 2 — топдаун, 3 — скроллер-шутер, 4 — босс.
## R — перезапустить арену, F — тряска, G — хит-стоп, P — частицы,
## H — полное HP, F4 — фуллскрин.

const PLAYER_SCENES: Array[String] = [
	"res://scenes/prefabs/player.tscn",
	"res://scenes/prefabs/topview_player.tscn",
	"res://scenes/prefabs/scroller_shooter_player.tscn",
	"res://scenes/prefabs/player.tscn",
]
const ENEMY_SCENE: String = "res://scenes/objects/Obj_201982402352644.tscn"
const PROFILE_PATROL: String = "res://resources/enemies/patrol.tres"
const PROFILE_RUSHER: String = "res://resources/enemies/rusher.tres"
const PROFILE_SHOOTER: String = "res://resources/enemies/shooter.tres"
const PROFILE_BOSS: String = "res://resources/enemies/boss.tres"

const TITLES: Array[String] = [
	"1  ПЛАТФОРМЕР",
	"2  ВИД СВЕРХУ",
	"3  СКРОЛЛЕР-ШУТЕР",
	"4  БОСС",
]

var arena_root: Node2D
var player: Node2D
var info_label: Label
var hp_label: Label
var current: int = 0
var _saved_lose_scene: String = ""


func _ready() -> void:
	_saved_lose_scene = SceneRouter.lose_scene
	# В полигоне смерть перезапускает арену, а не уводит в game_over.
	SceneRouter.lose_scene = ""
	RunState.max_hp = 100
	RunState.set_hp(100)
	_build_ui()
	GameEvents.hp_changed.connect(_on_hp_changed)
	var start_arena := 0
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--polygon-arena="):
			start_arena = arg.substr("--polygon-arena=".length()).to_int() - 1
	_load_arena(start_arena)


func _exit_tree() -> void:
	SceneRouter.lose_scene = _saved_lose_scene


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 6
	panel.offset_top = 6
	panel.offset_right = 300
	panel.offset_bottom = 132
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	info_label = Label.new()
	info_label.text = "ПОЛИГОН"
	vbox.add_child(info_label)

	hp_label = Label.new()
	vbox.add_child(hp_label)
	_on_hp_changed(RunState.hp, RunState.max_hp)

	var help := Label.new()
	help.text = "A/D или стрелки — движение\nZ — выстрел  X — мили\nR — рестарт  F — тряска  G — хит-стоп\nP — частицы  H — HP  F4 — фуллскрин"
	vbox.add_child(help)

	var arena_buttons := HBoxContainer.new()
	vbox.add_child(arena_buttons)
	for i in TITLES.size():
		var b := Button.new()
		b.text = str(i + 1)
		b.tooltip_text = TITLES[i]
		b.pressed.connect(_load_arena.bind(i))
		arena_buttons.add_child(b)

	var action_buttons := HBoxContainer.new()
	vbox.add_child(action_buttons)
	var hurt := Button.new()
	hurt.text = "Урон 15"
	hurt.pressed.connect(_damage_player)
	action_buttons.add_child(hurt)
	var shake := Button.new()
	shake.text = "Тряска"
	shake.pressed.connect(_test_shake)
	action_buttons.add_child(shake)
	var stop := Button.new()
	stop.text = "Хит-стоп"
	stop.pressed.connect(_test_hit_stop)
	action_buttons.add_child(stop)
	var particles := Button.new()
	particles.text = "Частицы"
	particles.pressed.connect(_test_particles)
	action_buttons.add_child(particles)


func _on_hp_changed(cur: int, mx: int) -> void:
	if hp_label != null:
		hp_label.text = "HP: %d / %d" % [cur, mx]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_1: _load_arena(0)
		KEY_2: _load_arena(1)
		KEY_3: _load_arena(2)
		KEY_4: _load_arena(3)
		KEY_R: _load_arena(current)
		KEY_F: _test_shake()
		KEY_G: _test_hit_stop()
		KEY_P: _test_particles()
		KEY_H: RunState.set_hp(RunState.max_hp)


func _damage_player() -> void:
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(15, player.global_position + Vector2(40, 0))


func _test_shake() -> void:
	GameEvents.request_shake("heavy", 1.0)


func _test_hit_stop() -> void:
	GameEvents.request_hit_stop("boss", 1.0)


func _test_particles() -> void:
	var pos := Vector2(240.0, 150.0)
	if is_instance_valid(player):
		pos = player.global_position + Vector2(0.0, -12.0)
	GameEvents.request_burst("hit", pos, Color(1.0, 0.86, 0.32, 1.0))
	GameEvents.request_burst("dust", pos + Vector2(22.0, 10.0), Color(0.62, 0.66, 0.72, 1.0))
	GameEvents.request_burst("muzzle", pos + Vector2(-22.0, 0.0), Color(1.0, 1.0, 0.72, 1.0), Vector2.RIGHT)
	GameEvents.request_burst("death", pos + Vector2(0.0, -24.0), Color(1.0, 0.45, 0.75, 1.0))


func _load_arena(idx: int) -> void:
	current = clampi(idx, 0, TITLES.size() - 1)
	if arena_root != null:
		remove_child(arena_root)
		arena_root.queue_free()

	arena_root = Node2D.new()
	add_child(arena_root)

	match current:
		0: _build_platformer()
		1: _build_topview()
		2: _build_shooter()
		3: _build_boss()

	info_label.text = TITLES[current]


func _build_platformer() -> void:
	# Базовая арена: земля, стены и две платформы.
	_add_box(Vector2(0, 0), Vector2(480, 320), Color(0.12, 0.14, 0.20), false)
	_add_box(Vector2(0, 268), Vector2(480, 52), Color(0.16, 0.18, 0.24))
	_add_box(Vector2(0, 0), Vector2(12, 320), Color(0.20, 0.22, 0.30))
	_add_box(Vector2(468, 0), Vector2(12, 320), Color(0.20, 0.22, 0.30))
	_add_box(Vector2(140, 214), Vector2(120, 14), Color(0.28, 0.32, 0.40))
	_add_box(Vector2(320, 166), Vector2(110, 14), Color(0.28, 0.32, 0.40))

	player = _spawn_player(0, Vector2(70, 210))
	# Патрульный враг — проверка обычного платформера.
	_spawn_enemy(Vector2(330, 236), PROFILE_PATROL, {"mode": "platformer"})
	# Неподвижный стрелок: всегда смотрит на игрока и целится в центр тела.
	_spawn_enemy(Vector2(420, 236), PROFILE_SHOOTER, {
		"mode": "platformer",
		"speed": 0.0,
		"move_dir_mode": 0,
		"use_gravity": true,
		"can_shoot": true,
		"turn_to_player": 1,
		"shoot_dir": 0,
		"shoot_interval": 1.4,
		"bullet_speed": 260.0,
		"melee_enabled": false,
		"contact_damage_enabled": false,
	})


func _build_topview() -> void:
	_add_box(Vector2(0, 0), Vector2(480, 320), Color(0.13, 0.20, 0.18), false)
	_add_box(Vector2(150, 90), Vector2(60, 30), Color(0.30, 0.38, 0.32), false)
	_add_box(Vector2(300, 200), Vector2(70, 30), Color(0.30, 0.38, 0.32), false)
	player = _spawn_player(1, Vector2(90, 160))
	_spawn_enemy(Vector2(370, 100), PROFILE_SHOOTER, {"mode": "topview"})
	_spawn_enemy(Vector2(370, 230), PROFILE_SHOOTER, {"mode": "topview", "shoot_interval": 1.7})


func _build_shooter() -> void:
	_add_box(Vector2(0, 0), Vector2(480, 320), Color(0.10, 0.12, 0.22), false)
	player = _spawn_player(2, Vector2(80, 160))
	_spawn_enemy(Vector2(430, 90), PROFILE_SHOOTER, {"mode": "shooter", "can_shoot": true})
	_spawn_enemy(Vector2(430, 220), PROFILE_SHOOTER, {"mode": "shooter", "can_shoot": true})


func _build_boss() -> void:
	_add_box(Vector2(0, 268), Vector2(480, 52), Color(0.22, 0.14, 0.18))
	_add_box(Vector2(0, 0), Vector2(480, 270), Color(0.16, 0.10, 0.16), false)
	player = _spawn_player(3, Vector2(80, 220))
	_spawn_enemy(Vector2(360, 220), PROFILE_BOSS, {
		"mode": "platformer",
		"spawn_phase_clone": true,
		"shake_on_death": true,
	})


func _spawn_player(idx: int, pos: Vector2) -> Node2D:
	var packed: PackedScene = load(PLAYER_SCENES[idx])
	var p := packed.instantiate() as Node2D
	arena_root.add_child(p)
	p.global_position = pos
	return p


func _spawn_enemy(pos: Vector2, profile_path: String, overrides: Dictionary) -> void:
	var packed: PackedScene = load(ENEMY_SCENE)
	var e := packed.instantiate() as Node2D
	var profile := load(profile_path) as EnemyProfile
	# Профиль применяем вручную ДО overrides: иначе profile.apply_to() в _ready()
	# перезапишет точечные настройки арены (mode, can_shoot, speed и т.д.).
	e.set("profile", profile)
	e.set("apply_profile_on_ready", false)
	if profile != null:
		profile.apply_to(e)
	for key in overrides.keys():
		e.set(key, overrides[key])
	if not e.is_in_group("enemies"):
		e.add_to_group("enemies")
	arena_root.add_child(e)
	e.global_position = pos


func _add_box(pos: Vector2, size: Vector2, color: Color, solid: bool = true) -> void:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	arena_root.add_child(rect)

	if not solid:
		return
	var body := StaticBody2D.new()
	body.position = pos + size / 2.0
	body.collision_layer = 1
	body.collision_mask = 1
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	arena_root.add_child(body)
