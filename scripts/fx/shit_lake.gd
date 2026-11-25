extends Node2D
class_name ShitLake
## Лужа из `shit-lake-1/2/3` под целью. секунду висит, потом фейдится и удаляется.

@export var hold_time: float = 1.0
@export var fade_time: float = 0.35
@export var auto_free: bool = true
@export var x_scatter: float = 9.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("shit_lake")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_as_relative = false


## Вызывается после add_child(), когда @onready уже проинициализирован.
func play(tex: Texture2D, z: int = 1) -> void:
	if not is_instance_valid(self) or sprite == null:
		return
	if tex != null:
		sprite.texture = tex
	z_index = z
	sprite.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_interval(maxf(0.0, hold_time))
	tween.tween_property(sprite, "modulate:a", 0.0, maxf(0.05, fade_time))
	if auto_free:
		tween.tween_callback(queue_free)
