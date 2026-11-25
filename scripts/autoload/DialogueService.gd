extends Node
## Диалоги по ID файла: res://dialogue/popup_<popup_index>.dialogue.
## Словаря реплик больше нет: создал .dialogue-файл, поставил popup_index
## на объекте (COLLECTABLE/SWITCH/KEY/...) — и диалог вызывается сам.

const DIALOGUE_DIR: String = "res://dialogue"
const POPUP_PREFIX: String = "popup_"
const POPUP_EXT: String = ".dialogue"
const START_CUE: String = "start"

var popup_panel: PanelContainer
var popup_label: Label
var is_popup_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	popup_panel = PanelContainer.new()
	popup_panel.visible = false
	popup_panel.set_anchors_preset(Control.PRESET_CENTER)
	popup_panel.custom_minimum_size = Vector2(520, 220)
	popup_panel.offset_left = -260
	popup_panel.offset_top = -110
	popup_panel.offset_right = 260
	popup_panel.offset_bottom = 110
	layer.add_child(popup_panel)
	popup_label = Label.new()
	popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_panel.add_child(popup_label)
	var dm := _dialogue_manager()
	if dm != null and dm.has_signal("dialogue_ended"):
		dm.dialogue_ended.connect(_on_dialogue_ended)


## Путь к файлу диалога по его ID. Единая точка для всех вызовов.
static func popup_path(idx: int) -> String:
	return "%s/%s%d%s" % [DIALOGUE_DIR, POPUP_PREFIX, idx, POPUP_EXT]


## Есть ли файл диалога с таким ID. Именно это, а не словарь, решает,
## можно ли показывать popup.
static func has_popup(idx: int) -> bool:
	if idx <= 0:
		return false
	var path := popup_path(idx)
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


## Все ID, для которых есть popup_*.dialogue (для инспектора/отладки).
static func available_ids() -> Array[int]:
	var ids: Array[int] = []
	var dir := DirAccess.open(DIALOGUE_DIR)
	if dir == null:
		return ids
	for file_name in dir.get_files():
		if not file_name.begins_with(POPUP_PREFIX) or not file_name.ends_with(POPUP_EXT):
			continue
		var middle: String = file_name.substr(
			POPUP_PREFIX.length(),
			file_name.length() - POPUP_PREFIX.length() - POPUP_EXT.length()
		)
		if middle.is_valid_int():
			var id := middle.to_int()
			if id > 0:
				ids.append(id)
	ids.sort()
	return ids


## Текст реплик для встроенного баллона (если Dialogue Manager недоступен).
## Читается прямо из .dialogue: имя перед ':' убираем, служебные строки
## '~ cue' / '=> ...' пропускаем. Из собранной игры, где исходника нет,
## берём реплики из импортированного ресурса.
static func popup_lines(idx: int) -> PackedStringArray:
	var lines := PackedStringArray()
	if not has_popup(idx):
		return lines
	var path := popup_path(idx)
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			while not file.eof_reached():
				var raw: String = file.get_line().strip_edges()
				if raw.is_empty() or raw.begins_with("~") or raw.begins_with("=>") or raw.begins_with("#"):
					continue
				var colon := raw.find(":")
				if colon > 0:
					raw = raw.substr(colon + 1).strip_edges()
				if not raw.is_empty():
					lines.append(raw)
			file.close()
			return lines
	var resource := load(path) as Resource
	if resource == null:
		return lines
	var resource_lines: Variant = resource.get("lines")
	if not (resource_lines is Array):
		return lines
	for item in (resource_lines as Array):
		if item is DialogueLine:
			var line := item as DialogueLine
			if not line.text.is_empty():
				lines.append(line.text)
	return lines


func _dialogue_manager() -> Node:
	var dm := get_node_or_null("/root/DialogueManager")
	if dm == null:
		for node in get_tree().root.get_children():
			if node.has_method("show_dialogue_balloon"):
				dm = node
				break
	return dm


func _make_always(node: Node) -> void:
	if node == null:
		return
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_make_always(child)


func _on_dialogue_ended(_resource = null) -> void:
	_close_dialogue()


func _close_dialogue() -> void:
	is_popup_open = false
	popup_panel.visible = false
	RunState.set_dialogue_active(false)
	get_tree().paused = false
	Input.flush_buffered_events()


func _process(_delta) -> void:
	if is_popup_open and Input.is_action_just_pressed("ui_accept"):
		_close_dialogue()


func show_popup(idx: int) -> void:
	if idx <= 0:
		return
	if is_popup_open or RunState.dialogue_active:
		return
	if not has_popup(idx):
		push_warning("DialogueService: нет файла %s — создай его или поправь popup_index" % popup_path(idx))
		return
	var dm := _dialogue_manager()
	var path := popup_path(idx)
	if dm != null and ResourceLoader.exists(path):
		var resource := load(path) as Resource
		if resource != null:
			_open_balloon(dm, resource)
			return
	var lines := popup_lines(idx)
	if lines.is_empty():
		push_warning("DialogueService: диалог %d пустой" % idx)
		return
	popup_label.text = "\n".join(lines)
	popup_panel.visible = true
	is_popup_open = true
	RunState.set_dialogue_active(true)
	get_tree().paused = true


func _open_balloon(dm: Node, resource: Resource) -> void:
	RunState.set_dialogue_active(true)
	var bgm: Node = null
	if get_tree().current_scene != null:
		bgm = get_tree().current_scene.get_node_or_null("BGM")
	if bgm != null:
		bgm.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var balloon: Node = dm.show_dialogue_balloon(resource, START_CUE)
	_make_always(balloon)
