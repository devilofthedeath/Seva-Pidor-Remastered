extends "res://scripts/roles/role_base.gd"
## POWERUP — усиление: очки, лечение, выдача пушки.

func _on_body(body):
	if not is_active or not body.is_in_group("player"):
		return
	if action_score != 0:
		GameState.add_score(action_score)
	if action_health > 0 and body.has_method("heal"):
		body.heal(action_health)
	if grant_gun:
		body.has_gun = true
	if popup_index > 0:
		GameState.show_popup(popup_index)
	if gc_id != "":
		GameState.mark_cleared(gc_id)
	queue_free()
