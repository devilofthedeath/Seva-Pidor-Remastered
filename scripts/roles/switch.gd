extends "res://scripts/roles/role_base.gd"
## SWITCH — активируется прикосновением, пулей или ударом.
## Пуля срабатывает только если у свитча явно включён `by_bullet`.

func _on_body(body):
	if is_active and not ignore_player and body.is_in_group("player"):
		_activate_switch()


func on_bullet_hit():
	if not is_active or not by_bullet:
		return
	_activate_switch()


func on_melee_hit():
	_activate_switch()
