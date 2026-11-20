extends Node
## Хит-стоп: короткое замедление времени на момент удара.
## Таймер живёт в реальном времени (ignore_time_scale), поэтому всегда отпускает.

const PRESETS: Dictionary = {
	"light": { "duration": 0.035, "scale": 0.18 },
	"hit":   { "duration": 0.060, "scale": 0.08 },
	"heavy": { "duration": 0.100, "scale": 0.04 },
	"death": { "duration": 0.140, "scale": 0.03 },
	"boss":  { "duration": 0.180, "scale": 0.02 },
}

@export var enabled: bool = true
@export var max_duration: float = 0.20

var _saved_scale: float = 1.0
var _active: bool = false
var _ends_at_msec: int = 0
var _timer: SceneTreeTimer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameEvents != null:
		GameEvents.hit_stop_requested.connect(_on_request)
	if get_tree().has_signal("scene_changed"):
		get_tree().scene_changed.connect(_on_scene_changed)


func _on_scene_changed(_old_scene = null, _new_scene = null) -> void:
	stop()


func _on_request(preset: String, strength: float) -> void:
	var preset_name := preset
	if preset_name == "" or not PRESETS.has(preset_name):
		preset_name = "hit"
	var cfg: Dictionary = PRESETS[preset_name]
	var duration := float(cfg.get("duration", 0.06)) * clampf(strength, 0.25, 2.0)
	hit(duration, float(cfg.get("scale", 0.08)))


## duration в секундах реального времени, scale — множитель Engine.time_scale.
func hit(duration: float, scale: float = 0.08) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec()
	var wanted := int(clampf(duration, 0.01, max_duration) * 1000.0)
	var end := now + wanted
	# Уже идёт хит-стоп: продлеваем только если новый запрос длиннее.
	if _active and end <= _ends_at_msec:
		return
	if not _active:
		_saved_scale = Engine.time_scale
	_active = true
	_ends_at_msec = end
	Engine.time_scale = minf(maxf(Engine.time_scale, 0.001), clampf(scale, 0.01, 1.0))
	if _timer != null and is_instance_valid(_timer):
		_timer.timeout.disconnect(_finish)
	_timer = get_tree().create_timer((end - now) / 1000.0, true, false, true)
	_timer.timeout.connect(_finish)


func _finish() -> void:
	if Time.get_ticks_msec() < _ends_at_msec - 20:
		return
	stop()


func stop() -> void:
	if _timer != null and is_instance_valid(_timer):
		if _timer.timeout.is_connected(_finish):
			_timer.timeout.disconnect(_finish)
	_timer = null
	if _active:
		Engine.time_scale = _saved_scale
	_active = false
	_ends_at_msec = 0
