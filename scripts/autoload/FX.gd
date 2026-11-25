extends Node
## Сервис эффектов. Слушает GameEvents и создаёт сцены-частицы в текущей сцене.
## Прямой вызов: FX.burst(pos, "hit", Color.WHITE, Vector2.RIGHT).
## Через шину: GameEvents.request_burst("hit", pos, color, dir).

const BURST_SCENE: PackedScene = preload("res://scenes/fx/pixel_burst.tscn")
const SHIT_LAKE_SCENE: PackedScene = preload("res://scenes/fx/shit_lake.tscn")
const SHIT_LAKE_TEXTURES: Array[String] = [
	"res://assets/sprites/shit-lake-1.png",
	"res://assets/sprites/shit-lake-2.png",
	"res://assets/sprites/shit-lake-3.png",
]
## Слои 1 (статические/движущиеся блоки, пол) и 3 (пушабли).
const SHIT_LAKE_FLOOR_MASK: int = 1 | 4
const SHIT_LAKE_MAX_DROP: float = 512.0
## У спрайта лужи видимая часть заканчивается на +7 px от центра.
const SHIT_LAKE_GROUND_OFFSET: float = 7.0


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


## Лужа от какашки-пули: ищем пол лучом вниз от точки попадания и кладём
## спрайт на поверхность. Если пола нет — лужи не будет (не в воздухе).
func shit_lake(impact: Vector2, target: Node2D = null, z: int = 0) -> ShitLake:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var parent: Node = tree.current_scene
	if parent == null:
		parent = tree.root

	var x := impact.x
	if target != null and is_instance_valid(target):
		x = _collision_center_x(target)

	var from := Vector2(x, impact.y - 16.0)
	var to := Vector2(x, impact.y + SHIT_LAKE_MAX_DROP)
	var space := tree.root.world_2d.direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, to, SHIT_LAKE_FLOOR_MASK)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return null

	var pos: Vector2 = hit["position"]
	pos.x += randf_range(-9.0, 9.0)
	pos.y -= SHIT_LAKE_GROUND_OFFSET

	var tex := load(SHIT_LAKE_TEXTURES[randi_range(0, SHIT_LAKE_TEXTURES.size() - 1)]) as Texture2D
	var fx := SHIT_LAKE_SCENE.instantiate() as ShitLake
	if fx == null:
		return null
	parent.add_child(fx)
	fx.global_position = pos
	fx.play(tex, z)
	return fx


static func _collision_center_x(node: Node2D) -> float:
	for child in node.get_children():
		if child is CollisionShape2D:
			return (child as CollisionShape2D).global_position.x
	return node.global_position.x


func _on_burst_requested(preset: String, position: Vector2, color: Color, direction: Vector2) -> void:
	burst(position, preset, color, direction)
