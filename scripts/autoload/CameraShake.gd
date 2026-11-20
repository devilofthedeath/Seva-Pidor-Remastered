extends Node
## Тряска камеры через Phantom Camera.
## Важно: НЕ создаём PhantomCameraHost/PhantomCamera2D — они делают Camera2D
## top_level и перехватывают трансформ, из-за чего камера перестаёт следовать
## за игроком. Берём у плагина только noise-ресурс и эмиттер, а смещение
## применяем к offset/rotation текущей Camera2D сами.

const NoiseResourceScript: Script = preload("res://addons/phantom_camera/scripts/resources/phantom_camera_noise_2d.gd")
const EmitterScript: Script = preload("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_noise_emitter_2d.gd")

## amplitude, frequency, duration, decay. duration/decay в секундах.
const PRESETS: Dictionary = {
	"light":  { "amplitude": 8.0,  "frequency": 22.0, "duration": 0.06, "decay": 0.10 },
	"hit":    { "amplitude": 16.0, "frequency": 26.0, "duration": 0.10, "decay": 0.16 },
	"heavy":  { "amplitude": 30.0, "frequency": 20.0, "duration": 0.16, "decay": 0.26 },
	"death":  { "amplitude": 42.0, "frequency": 16.0, "duration": 0.25, "decay": 0.45 },
	"boss":   { "amplitude": 24.0, "frequency": 14.0, "duration": 0.35, "decay": 0.40 },
}

@export var enabled: bool = true
@export var emitter_layer: int = 1
## Через сколько секунд отсутствия сигнала считаем тряску законченной.
@export var reset_delay: float = 0.08

var _noise = null
var _emitter = null
var _current_cam_id: int = -1
var _base_offset: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0
var _noise_active: bool = false
var _noise_since: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Даём PhantomCameraManager (autoload плагина) зарегистрироваться.
	await get_tree().process_frame
	_setup_emitter()
	var manager := get_node_or_null("/root/PhantomCameraManager")
	if manager != null and manager.has_signal("noise_2d_emitted"):
		manager.noise_2d_emitted.connect(_on_noise_emitted)
	else:
		push_warning("CameraShake: PhantomCameraManager не найден — проверь плагин в Project Settings.")
	if GameEvents != null:
		GameEvents.shake_requested.connect(_on_shake_requested)
	if get_tree().has_signal("scene_changed"):
		get_tree().scene_changed.connect(_on_scene_changed)


func _setup_emitter() -> void:
	if _emitter != null:
		return
	if get_node_or_null("/root/PhantomCameraManager") == null:
		return
	_noise = NoiseResourceScript.new()
	_noise.amplitude = 16.0
	_noise.frequency = 26.0
	_noise.positional_noise = true
	_noise.rotational_noise = false

	_emitter = EmitterScript.new()
	_emitter.name = "CameraShakeEmitter"
	_emitter.noise = _noise
	_emitter.noise_emitter_layer = emitter_layer
	_emitter.continuous = false
	_emitter.duration = 0.1
	_emitter.decay_time = 0.16
	add_child(_emitter)


func _on_shake_requested(preset: String, strength: float) -> void:
	shake(preset, strength)


func _on_scene_changed(_old_scene = null, _new_scene = null) -> void:
	_reset_camera()
	_current_cam_id = -1


func _process(delta: float) -> void:
	if not _noise_active:
		# Держим базу свежей, пока камеру никто не трясёт.
		var cam_now := _find_current_camera(get_tree().root)
		if cam_now != null:
			var id_now := cam_now.get_instance_id()
			if id_now != _current_cam_id:
				_current_cam_id = id_now
			_base_offset = cam_now.offset
			_base_rotation = cam_now.rotation
		return
	_noise_since += delta
	if _noise_since >= maxf(0.03, reset_delay):
		_reset_camera()


func _on_noise_emitted(noise_output: Transform2D, layer: int) -> void:
	if not enabled or _emitter == null:
		return
	if (layer & emitter_layer) == 0:
		return
	var cam := _find_current_camera(get_tree().root)
	if cam == null:
		return
	var id := cam.get_instance_id()
	if id != _current_cam_id:
		_reset_camera()
		_current_cam_id = id
		_base_offset = cam.offset
		_base_rotation = cam.rotation
	cam.offset = _base_offset + noise_output.origin
	if not cam.ignore_rotation:
		cam.rotation = _base_rotation + noise_output.get_rotation()
	_noise_active = true
	_noise_since = 0.0


func _reset_camera() -> void:
	if _current_cam_id <= 0:
		return
	var cam := _find_by_id(get_tree().root, _current_cam_id)
	if cam != null and is_instance_valid(cam):
		cam.offset = _base_offset
		cam.rotation = _base_rotation
	_noise_active = false
	_noise_since = 0.0


func _find_by_id(node: Node, id: int) -> Camera2D:
	if node.get_instance_id() == id and node is Camera2D:
		return node as Camera2D
	for child in node.get_children():
		var found := _find_by_id(child, id)
		if found != null:
			return found
	return null


func _find_current_camera(node: Node) -> Camera2D:
	if node is Camera2D and (node as Camera2D).is_current():
		return node as Camera2D
	for child in node.get_children():
		var found := _find_current_camera(child)
		if found != null:
			return found
	return null


## preset — имя из PRESETS ("light"/"hit"/"heavy"/"death"/"boss") или число = сила.
func shake(preset = "hit", strength: float = 1.0) -> void:
	if not enabled or _emitter == null or _noise == null:
		return
	var preset_name := "hit"
	var mult := strength
	if preset is String or preset is StringName:
		preset_name = str(preset)
	elif preset is int or preset is float:
		mult = float(preset)
	var cfg: Dictionary = PRESETS.get(preset_name, PRESETS["hit"])

	_noise.amplitude = float(cfg.get("amplitude", 16.0)) * maxf(0.0, mult)
	_noise.frequency = float(cfg.get("frequency", 26.0))
	_emitter.duration = maxf(0.02, float(cfg.get("duration", 0.1)))
	_emitter.decay_time = maxf(0.02, float(cfg.get("decay", 0.16)))
	_emitter.emit()
	_noise_active = true
	_noise_since = 0.0


func shake_for_damage(amount: int) -> void:
	if amount >= 30:
		shake("heavy")
	elif amount >= 12:
		shake("hit")
	else:
		shake("light")


func stop() -> void:
	if _emitter != null:
		_emitter.stop(false)
	_reset_camera()
