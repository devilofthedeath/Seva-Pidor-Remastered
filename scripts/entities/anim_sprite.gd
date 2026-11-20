extends Sprite2D
@export var fps: float = 10.0
@export var freeze_last: bool = false
var timer: float = 0.0

func _process(delta):
	if hframes <= 1:
		return
	timer += delta
	# Оригинальные 20 fps выглядят слишком дёргано — ограничиваем 12.
	var rate = min(max(1.0, fps), 12.0)
	if timer >= 1.0 / rate:
		timer = 0.0
		if freeze_last and frame >= hframes - 1:
			return
		frame = (frame + 1) % hframes
