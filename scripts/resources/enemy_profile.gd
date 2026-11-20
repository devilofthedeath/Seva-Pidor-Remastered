@tool
extends Resource
class_name EnemyProfile
## Профиль врага: набор настроек, который можно переиспользовать в разных сценах.
## Создай .tres через Inspector: right click -> New Resource -> EnemyProfile.
## В сцене врага выбери profile и включи apply_on_ready.

@export_multiline var description: String = ""

@export_group("Основное")
@export_enum("platformer", "topview", "shooter") var mode: String = "platformer"
@export var speed: float = 90.0
@export var max_hp: int = 30
@export var hp: int = 30
@export var boss: bool = false

@export_group("Урон и движение")
@export var contact_damage: int = 10
@export var contact_range: float = 42.0
@export var use_gravity: bool = true
@export_enum("None", "Left", "Right", "Random") var move_dir_mode: int = 1
@export_enum("Static", "Sine X", "Sine Y", "Circle", "Boss follow") var move_shape: int = 0
@export var aggro_radius: float = 0.0
@export var aggro_speed_multiplier: float = 1.0

@export_group("Бой")
@export var melee_enabled: bool = true
@export var melee_range: float = 72.0
@export var melee_dash_speed: float = 650.0
@export var melee_cooldown: float = 1.3
@export var can_shoot: bool = false
@export var shoot_interval: float = 1.0
@export var bullet_speed: float = 300.0
@export var bullet_damage: int = 10
@export var projectiles_per_shot: int = 1
@export var spread_angle_deg: float = 0.0

@export_group("Обратная связь")
@export var show_health_bar: bool = false
@export var shake_on_death: bool = false
@export var death_shake_preset: String = "heavy"
@export var spawn_phase_clone: bool = true


## Копирует настройки профиля во врага. Вызывается из enemy.gd в _ready().
func apply_to(enemy: Node) -> void:
	if enemy == null:
		return
	for key in _fields():
		enemy.set(key, get(key))


func _fields() -> Array[StringName]:
	return [
		&"mode", &"speed", &"max_hp", &"hp", &"boss",
		&"contact_damage", &"contact_range", &"use_gravity",
		&"move_dir_mode", &"move_shape", &"aggro_radius", &"aggro_speed_multiplier",
		&"melee_enabled", &"melee_range", &"melee_dash_speed", &"melee_cooldown",
		&"can_shoot", &"shoot_interval", &"bullet_speed", &"bullet_damage",
		&"projectiles_per_shot", &"spread_angle_deg",
		&"show_health_bar", &"shake_on_death", &"death_shake_preset", &"spawn_phase_clone",
	]
