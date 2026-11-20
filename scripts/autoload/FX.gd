extends Node
## Сервис эффектов. Слушает GameEvents и создаёт сцены-частицы в текущей сцене.
## Прямой вызов: FX.burst(pos, "hit", Color.WHITE, Vector2.RIGHT).
## Через шину: GameEvents.request_burst("hit", pos, color, dir).

const BURST_SCENE: PackedScene = preload("res://scenes/fx/pixel_burst.tscn")


func _ready() -> void:
	GameEvents.burst_requested.connect(_on_burst_requested)


func burst(position: Vector2, preset: String = "hit", color: Color = Color.WHITE, direction: Vector2 = Vector2.ZERO) -> PixelBurst:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null

	var parent: Node = tree.current_scene
	if parent == null:
		parent = tree.root
	var fx := BURST_SCENE.instantiate() as PixelBurst
	if fx == null:
		return null

	# Свойства выставляем до add_child(), чтобы _ready() сразу применил пресет.
	fx.preset = preset
	fx.tint = color
	fx.emit_direction = direction
	parent.add_child(fx)
	fx.global_position = position
	# Старт эмиссии — только после позиционирования, синхронно.
	fx.emit_burst()
	return fx


func _on_burst_requested(preset: String, position: Vector2, color: Color, direction: Vector2) -> void:
	burst(position, preset, color, direction)
