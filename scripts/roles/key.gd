extends "res://scripts/roles/role_base.gd"
## KEY — ключ: увеличивает счётчик ключей.

func _on_body(body):
	if not is_active or not body.is_in_group("player"):
		return
	GameState.keys += 1
	if action_score != 0:
		GameState.add_score(action_score)
	if popup_index > 0:
		GameState.show_popup(popup_index)
	if gc_id != "":
		GameState.mark_cleared(gc_id)
	queue_free()
