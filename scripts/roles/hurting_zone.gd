extends "res://scripts/roles/role_base.gd"
## HURTING ZONE — наносит урон при касании.

func _on_body(body):
	if is_active and body.has_method("take_damage"):
		body.take_damage(damage)
