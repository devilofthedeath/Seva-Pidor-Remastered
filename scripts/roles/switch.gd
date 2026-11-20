extends "res://scripts/roles/role_base.gd"
## SWITCH — активируется прикосновением, пулей или ударом.

func _on_body(body):
	if is_active and not ignore_player and body.is_in_group("player"):
		_activate_switch()

func on_bullet_hit():
	_activate_switch()

func on_melee_hit():
	_activate_switch()
