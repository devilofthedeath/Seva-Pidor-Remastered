extends "res://scripts/roles/role_base.gd"
## DOOR — открывается/закрывается по свитчу.

func _on_switch_special(num: int, state: bool):
	if num == listener_num:
		visible = not state
		set_deferred("monitoring", not state)
