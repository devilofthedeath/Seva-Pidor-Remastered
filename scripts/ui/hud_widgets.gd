extends Control
@export var widget_type: String = "HEALTH"
@export var timer_id: int = 1
@export var default_seconds: float = 10.0
@export var timer_param1: int = 0
@export var timer_action: int = 1
@export var listener_num: int = 0
@export var auto_start: bool = false
@export var timer_song_stream: AudioStream

var time_left: float = 0.0
var running: bool = false

func _ready():
	# Группы оставляем для старых объектов, но основной канал — шина событий.
	if GameEvents != null:
		GameEvents.hp_changed.connect(_on_hp_changed)
		GameEvents.score_changed.connect(_on_score_changed)
	if widget_type == "HEALTH":
		add_to_group("hud_health")
		update_hp(GameState.hp, GameState.max_hp)
	elif widget_type == "":
		add_to_group("hud_score")
		update_score(GameState.score)
	elif widget_type == "TIMER":
		add_to_group("game_timers")
		if listener_num > 0:
			add_to_group("switch_listeners")
		if auto_start:
			on_start_timer(timer_id, default_seconds)

func on_switch_event(num: int, state: bool):
	if num == listener_num and state:
		on_start_timer(timer_id, default_seconds)

func _on_hp_changed(cur: int, mx: int) -> void:
	update_hp(cur, mx)
	# Старые ноды всё ещё слушают группу — дублировать не надо,
	# поэтому здесь только прямой вызов этого виджета.


func _on_score_changed(value: int) -> void:
	update_score(value)


func update_hp(cur: int, mx: int):
	if has_node("Bar"):
		$Bar.max_value = mx
		$Bar.value = cur

func update_score(val: int):
	if has_node("Lbl"):
		$Lbl.text = "SCORE: " + str(val)

func on_start_timer(tid: int, secs: float):
	if tid != timer_id:
		return
	time_left = secs if secs > 0 else default_seconds
	running = true
	visible = true

func _process(delta):
	if widget_type == "TIMER" and running:
		time_left -= delta
		if has_node("Lbl"):
			$Lbl.text = str(ceil(max(0.0, time_left)))
		if time_left <= 0.0:
			running = false
			# 2/3/1 - действие со свитчем/уровнем, 5 - смена музыки
			if timer_action == 5 and timer_song_stream != null:
				var bgm = get_tree().current_scene.get_node_or_null("BGM")
				if bgm != null:
					bgm.stream = timer_song_stream
					bgm.play()
			else:
				GameState.on_timer_action(timer_action, timer_param1)
