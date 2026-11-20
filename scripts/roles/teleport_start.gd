extends "res://scripts/roles/role_base.gd"
## TELEPORT START — переносит игрока к TELEPORT END.

func _on_body(body):
	if not is_active or not body.is_in_group("player"):
		return
	var ends = get_tree().get_nodes_in_group("teleport_end")
	if ends.size() > 0:
		body.global_position = ends.front().global_position
