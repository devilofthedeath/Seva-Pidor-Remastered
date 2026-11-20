extends Node
## Общая шина сигналов. Никакого состояния — только события.
## Используй её вместо прямых call_group("hud_...", ...) и ссылок на GameState.

signal hp_changed(current: int, maximum: int)
signal score_changed(value: int)
signal keys_changed(value: int)
signal dialogue_state_changed(active: bool)
signal switch_changed(num: int, state: bool)
signal timer_started(tid: int, seconds: float)
signal enemy_died(enemy: Node)
signal level_changed(path: String)
## preset: "light" / "hit" / "heavy" / "death" / "boss"
signal shake_requested(preset: String, strength: float)
## preset: "light" / "hit" / "heavy" / "death" / "boss"
signal hit_stop_requested(preset: String, strength: float)
## preset: "hit" / "death" / "dust" / "muzzle"
signal burst_requested(preset: String, position: Vector2, color: Color, direction: Vector2)


func emit_hp(current: int, maximum: int) -> void:
	hp_changed.emit(current, maximum)


func emit_score(value: int) -> void:
	score_changed.emit(value)


func emit_keys(value: int) -> void:
	keys_changed.emit(value)


func emit_dialogue(active: bool) -> void:
	dialogue_state_changed.emit(active)


func emit_switch(num: int, state: bool) -> void:
	switch_changed.emit(num, state)


func emit_timer(tid: int, seconds: float) -> void:
	timer_started.emit(tid, seconds)


func emit_enemy_died(enemy: Node) -> void:
	enemy_died.emit(enemy)


func emit_level_changed(path: String) -> void:
	level_changed.emit(path)


func request_shake(preset: String, strength: float = 1.0) -> void:
	shake_requested.emit(preset, strength)


func request_hit_stop(preset: String = "hit", strength: float = 1.0) -> void:
	hit_stop_requested.emit(preset, strength)


func request_burst(preset: String = "hit", position: Vector2 = Vector2.ZERO, color: Color = Color.WHITE, direction: Vector2 = Vector2.ZERO) -> void:
	burst_requested.emit(preset, position, color, direction)
