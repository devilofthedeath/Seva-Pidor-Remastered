extends Node

@export var level_width: int = 480
@export var level_height: int = 320


func _ready():
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var cam = players[0].get_node_or_null("Camera2D")
	if cam == null:
		return
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = level_width
	cam.limit_bottom = level_height
	GameState.level_bottom = level_height + 120
