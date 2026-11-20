extends "res://scripts/roles/role_base.gd"
## FINISH LEVEL — переход на следующий уровень (с условиями из .obj).

var finish_done: bool = false


func _process(_delta):
	if not finish_done and need_cleared != "" and _can_finish():
		finish_done = true
		GameState.next_level()


func _on_body(body):
	if not is_active or not body.is_in_group("player"):
		return
	if _can_finish():
		GameState.next_level()
