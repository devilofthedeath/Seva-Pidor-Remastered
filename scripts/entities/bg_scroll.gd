extends Node2D

@export var scroll_factor: float = 1.0


func _process(_delta):
	if scroll_factor <= 0.0:
		position = Vector2.ZERO
		return
	# Берём именно canvas-трансформу: она учитывает сглаживание камеры,
	# поэтому фон не «дёргается» относительно мира.
	position = -get_viewport().get_canvas_transform().origin * scroll_factor
