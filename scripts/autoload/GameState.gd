extends Node

var switches: Dictionary = {}
var popups: Dictionary = {1: ['Привет Сева', 'Эта игра про тебя прикол', 'Я Димка кста', 'Ты, я полагаю, сильно удивлен, что я выше тебя', 'На самом деле тебе так кажется', 'Ты просто сутулишься сильно', 'Выпрямись, черт побери!!', 'Зажми кнопку прыжка,чтобы выйти из диалога'], 2: ['Опа это снова я', 'Видишь там скейт?', 'Я знаю, ты хочешь на нем покататься', 'Для этого просто залезь на него и нажми "C"'], 3: ['Ну что, понравилось кататься?)', 'Да мне похуй! :))))', 'Позер ебаный', 'Пошли лучше в саме позависаем'], 5: ['Слыш чо чолка длиная ты не поцан чтоли', 'Телка что ли)', 'Ты че бегаешь?)', '...епт...'], 6: ['Ты охуел? Ты моего друга убил!!!!', 'Брат за брата сукаааа!!!!!', 'УНИЧТОЖУ'], 4: ['Ты слышал? Этот негодяй справа до тебя доебался!', 'Отвесь-ка ему тумаков!!!', 'С - удар ногой,', 'B - высрать какашку-мину', 'Если ты умер', 'И не хочешь начинать игру сначала,', 'Просто нажми на кнопку рестарта,', 'И уровень начнется заново.'], 8: ['Молодчинка, Сева!', 'Прости, что убежал', 'Пошли посмотрим, что там по энергосам', 'А потом к Владу пойдём'], 15: ['Ура ключб)'], 19: ['Охранник повержен, вы получили 1 банку))', 'Отнесите ее в тележку.'], 18: ['Пятая банка у охранника', 'Тебе нужно убить его, чтобы получить её.', '*Зажми "направо", чтобы выйти*'], 20: ['Я стою тут уже 16 часов и не знаю,', 'Какие чипсы лучше взять:', 'С беконом или с крабом?', 'Наверное лучше с крабом, они вкуснее', 'Хотя нет, я уже ел чипсы с крабом вчера...', 'Возьму с беконом.', 'Или лучше с крабом....', 'Я никогда не найду ответ на этот вопрос......', 'А ты сам как думаешь?', 'Кстати, я не трачу твое время?'], 21: ['Ифеф энехгетики?', 'Я обоваю павер тох, мой любимый энехгетик)', 'Знаеф фто такое с*кс? Ихихихи', 'Я обоваю с*кс, хоть мне и 7', 'Ты внаеф фто такое дхотить?'], 22: ['Молодец!! Ты собрал все банки!!!', 'Теперь осталось самое интересное:', 'Постоять в этой очереди', 'Удачи, я тебя на улице подожду'], 16: ['Эй, ты!', 'Ты, нарушитель закона, думаешь,', 'Что сможешь остаться безнаказанным?', 'Это делаешь ты зря, амиго!', 'Я тебя поймаю!'], 17: ['Короче, собери по всему магазину 5 банок.', 'Банки появляются в разных местах постепенно,', 'одна за другой, то есть', 'как только ты подбираешь банку,', 'сразу же где-то появляется еще одна.', 'Все понял?', 'Я даю тебе 3 минуты, не больше', 'Поторопись.', 'Не забывай относить банки в тележку', 'Кстати, пока ты читал, уже прошло секунд 10'], 40: ['Эй, чел, ты не должен был проходить уровень так', 'Давай заново'], 41: ['АААА СЕВА ПОМОГИИИ', 'ЭТИ УБЛЮДКИ МЕНЯ ПОХИТИЛИ', 'ИСПОЛЬЗУЙ МОЁ НОВОЕ ИЗОБРЕТЕНИЕ - ГОВНОМЕТ!!!', 'Он соединен с твоей жопой', 'при помощи трубки, по которой говно', 'доставляется из жопы прямиков в', 'в пушку, из которой говно вылетает,', 'нанося урон противнику.'], 44: ['Это ты во всем виноват,', 'Слишком долго в очереди стоял', 'Пошли уже к Владу', 'Кстати, интересно...', 'Откуда в тебе столько говна?'], 42: ['ААА СЕВА НА ПОМОЩЬ Я ЗДЕСЬ!!!'], 45: ['Дима умер. Задание провалено. Перезапуск уровня...'], 46: ['ОХУЕТЬ', 'ПИЗДЕЕЕЕЕЦ', 'ЕБУЧИЙ КАРАУЛ, ГДЕ МЫ??', 'ПИЗДЕЦ, ВЕРХНЯЯ ТЕРРАСА', 'На часах 21:05,', 'Мы когда к владу придем?', 'Ладно, спокойно.', 'Мы можем приехать на твоем скейте', 'Но он сломан, у нас есть 8 деталей,', 'найди еще 3 детали для него'], 47: ['О пхивет, это опять ты?', 'Ифеф детали для фкейта??', 'А я люблю на фамокате катаца', 'А ефе я 1000 хублей в день захабатываю', 'Кфтати, детали мовно купить', 'У однаво дядиньки на востоки этово уровня'], 71: ['УРААААА', 'Наконец-то, еще немного,', 'и мы придём к Владу!!!', 'Кстати, на этот раз ты, видимо,', 'полностью убил того гиганта...', 'Молодец!!!'], 72: ['Пхивет, мы снова встретилифь!!', 'Что? Нет, я тебя не пхефледую...', 'Пхосто ты такой кхутой, и по тебе', 'Фохнут все дефки!!!!', 'Я хофю быть таким вэ....', 'Кфтати, мовно ф вами на нотёфку?', 'Нет? Ну ладно... Увидимфя...', 'Кфтати, меня вовут Илья.'], 73: ['Наконец-то, чел!!!', 'От дома Влада нас разделяет пара шагов!', 'И это приключение подойдет к концу.', 'Ну ладно, погнали!!!'], 48: ['Панки хой!!!', 'Фанатов сектор газа приветствую,', 'остальным соболезную!', 'Малой, ты чего хотел?', 'Детали?', 'Конечно, с тебя 50000 долларов', 'Времена нынче тяжелые', 'Ладно, могу отдать бесплатно', 'Для этого заставь выключить зумеров реп', 'Они на юге карты'], 76: ['Вооот, а потом Сева такой:', 'Пиу пиу пиу! Паф паф паф!', 'Так мы и добрались до сюда.', 'Что, Сева? Тебе нужен квест?', 'Походи пока по квартире Влада, не знаю', 'Ты можешь осматривать предметы, нажав B'], 77: ['Синтезатор.', 'Жаль, что вы не умеете играть'], 74: ['[Влад]', 'Я вас ненавижу за то, что вы так поздно пришли', 'Где вы так долго были??'], 75: ['[Данила]', 'Пипец, Сева, вы правда остановили банду ауешников?', 'Обалдеть, ну вы даёте, молодцы'], 78: ['На шкафу висит зеркало.', 'Вы видите свое отражение.', 'Лучше б вы его не видели.'], 79: ['Куртка Влада.', 'Никто не знает, как долго он ее носит,', 'но ходят легенды, что она старше вас.'], 80: ['Диван Влада.', 'На нём можно спать хоть вчетвером.'], 81: ['На часах почти 11 вечера...', 'За окном совсем темно.', 'Вас ждет длинная ночь.'], 82: ['Интересно, что Данила смотрит на компе?', 'Вы ничего не понимаете, но', 'Данила выглядит довольным.'], 49: ['Красавелла брателла', 'Вот тебе за это деталь!!!!!', 'Что? Тебе нужна ещё одна?', 'Хм... Что ж...', 'Тогда сразись со мной на арене!!!', 'Если ты победишь,', 'то я отдам тебе деталь!!!', 'За мной!!!'], 50: ['Чего ты хочешь?', 'Чтобы мы музыку выключили?', 'Ахахаах лол нет', 'Еще чего?', 'Шел бы ты отсюда', 'Тебе тут не рады', 'Мы тут хайпим'], 52: ['МЫ ТЕБЯ ПРЕДУПРЕЖДАЛИ', 'ГОТОВЬ ОЧКО'], 53: ['Извините,', 'вы не подскажите, где тут', 'Секонд хэнд?'], 54: ['Что я здесь делаю?', 'Ты чего, я не мог пропустить', 'этот бой!!!', 'Давай, Сева, я на тебя 50 рублей', 'Поставил, не подведи меня!', 'Удачи!!!'], 55: ['Ты... молодец...', 'Тебе удалось победить...', 'Подойди и забери деталь...', 'Ты заслужил....'], 56: ['АХАХАХХАХАХХАХАХА', 'ТЫ ЧТО, ПРАВДА ПОВЕРИЛ?', 'АХАХХАХАХАХАХ', 'И-ДИ-ОТ!!!', 'УМРИИИИИ', 'АХАХАХХАХАХХАХАХАХХХА'], 57: ['Эй! Т-так нечестно!', 'Нельзя влезать в битву!', 'По правилам он проиграл!!!'], 58: ['Ты цел?', 'Бери деталь, и у ходим отсюда.'], 60: ['Хах, он думал, что только у него', 'есть суперсилы, придурок', 'Ладно, забили, садись на скейт,', 'и поехали к Владу'], 83: ['Сева, что тебе нужно?', 'Расслабься.', 'Мы дошли до квартиры Влада,', 'Что может быть лучше?'], 99: ['Эй!!!!', 'Фальшстарт!!! Ты ударил раньше времени!!!', 'Ты поплатишься за это бесчинство'], 98: ['Значит, ты хочешь играть так...', 'Что ж, тогда я принимаю правила!!!']}
var level_order: Array = ['res://scenes/levels/LEVEL_2.tscn', 'res://scenes/levels/LEVEL_3.tscn', 'res://scenes/levels/LEVEL_4.tscn', 'res://scenes/levels/LEVEL_5.tscn', 'res://scenes/levels/LEVEL_6.tscn', 'res://scenes/levels/LEVEL_7.tscn', 'res://scenes/levels/LEVEL_8.tscn', 'res://scenes/levels/LEVEL_9.tscn', 'res://scenes/levels/LEVEL_10.tscn', 'res://scenes/levels/LEVEL_11.tscn', 'res://scenes/levels/LEVEL_12.tscn', 'res://scenes/levels/LEVEL_13.tscn', 'res://scenes/levels/LEVEL_14.tscn', 'res://scenes/levels/LEVEL_15.tscn', 'res://scenes/levels/LEVEL_16.tscn', 'res://scenes/levels/LEVEL_17.tscn', 'res://scenes/levels/LEVEL_18.tscn', 'res://scenes/levels/LEVEL_19.tscn', 'res://scenes/levels/LEVEL_20.tscn']
var victory_scene: String = "res://scenes/levels/titles.tscn"
var lose_scene: String = "res://scenes/levels/game_over.tscn"
var level_by_number: Dictionary = {2: 'res://scenes/levels/LEVEL_2.tscn', 3: 'res://scenes/levels/LEVEL_3.tscn', 4: 'res://scenes/levels/LEVEL_4.tscn', 5: 'res://scenes/levels/LEVEL_5.tscn', 10: 'res://scenes/levels/LEVEL_10.tscn', 16: 'res://scenes/levels/LEVEL_16.tscn', 6: 'res://scenes/levels/LEVEL_6.tscn', 7: 'res://scenes/levels/LEVEL_7.tscn', 8: 'res://scenes/levels/LEVEL_8.tscn', 9: 'res://scenes/levels/LEVEL_9.tscn', 11: 'res://scenes/levels/LEVEL_11.tscn', 18: 'res://scenes/levels/LEVEL_18.tscn', 19: 'res://scenes/levels/LEVEL_19.tscn', 12: 'res://scenes/levels/LEVEL_12.tscn', 13: 'res://scenes/levels/LEVEL_13.tscn', 14: 'res://scenes/levels/LEVEL_14.tscn', 15: 'res://scenes/levels/LEVEL_15.tscn', 17: 'res://scenes/levels/LEVEL_17.tscn', 20: 'res://scenes/levels/LEVEL_20.tscn'}
var known_switches: Array = [1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 30, 31, 32, 33, 34, 35, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 75, 76, 100]
var hp: int = 100
var max_hp: int = 100
var score: int = 0
var keys: int = 0
var cleared: Dictionary = {}
var level_bottom: int = 100000
var last_death_scene: String = ""
var SAVE_PATH: String = "user://seva_save.cfg"

var popup_panel: PanelContainer
var popup_label: Label
var is_popup_open: bool = false
var dialogue_active: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer = CanvasLayer.new()
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
	# Диалог ставит игру на паузу — снимаем её по сигналу окончания.
	var dm = _dialogue_manager()
	if dm != null and dm.has_signal("dialogue_ended"):
		dm.dialogue_ended.connect(_on_dialogue_ended)

func _dialogue_manager():
	var dm = get_node_or_null("/root/DialogueManager")
	if dm == null:
		for node in get_tree().root.get_children():
			if node.has_method("show_dialogue_balloon"):
				dm = node
				break
	return dm

func _make_always(node):
	if node == null:
		return
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_make_always(child)

func _on_dialogue_ended(_resource = null):
	dialogue_active = false
	get_tree().paused = false
	Input.flush_buffered_events()

func _process(_delta):
	if is_popup_open and Input.is_action_just_pressed("ui_accept"):
		popup_panel.visible = false
		is_popup_open = false
		dialogue_active = false
		get_tree().paused = false
		Input.flush_buffered_events()

func show_popup(idx: int):
	if idx <= 0 or not popups.has(idx):
		return
	# Если установлен Dialogue Manager — используем его и ставим игру на паузу.
	var dm = _dialogue_manager()
	var dpath = "res://dialogue/popup_%d.dialogue" % idx
	if dm != null and ResourceLoader.exists(dpath):
		dialogue_active = true
		var bgm = get_tree().current_scene.get_node_or_null("BGM")
		if bgm != null:
			bgm.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		var balloon = dm.show_dialogue_balloon(load(dpath), "start")
		# Баллон добавляется в текущую сцену и тоже был бы заморожен паузой.
		_make_always(balloon)
		return
	popup_label.text = "\n".join(popups[idx])
	popup_panel.visible = true
	is_popup_open = true
	dialogue_active = true
	get_tree().paused = true

func trigger_switch(num: int, mode: int = 2):
	if num <= 0:
		return
	var nxt = not switches.get(num, false) if mode == 2 else true
	switches[num] = nxt
	get_tree().call_group("switch_listeners", "on_switch_event", num, nxt)

func start_timer(tid: int, secs: float):
	if tid > 0:
		get_tree().call_group("game_timers", "on_start_timer", tid, secs)

func add_score(pts: int):
	score += pts
	get_tree().call_group("hud_score", "update_score", score)

func damage_player(dmg: int):
	hp = max(0, hp - dmg)
	get_tree().call_group("hud_health", "update_hp", hp, max_hp)
	if hp <= 0:
		hp = max_hp
		if lose_scene != "":
			get_tree().change_scene_to_file(lose_scene)
		else:
			get_tree().reload_current_scene()

func kill_player():
	hp = 0
	get_tree().call_group("hud_health", "update_hp", hp, max_hp)
	var cur = get_tree().current_scene
	if cur != null and cur.scene_file_path != lose_scene:
		last_death_scene = cur.scene_file_path
	if lose_scene != "":
		get_tree().change_scene_to_file(lose_scene)
	else:
		get_tree().reload_current_scene()

func retry_level():
	hp = max_hp
	get_tree().call_group("hud_health", "update_hp", hp, max_hp)
	if last_death_scene != "":
		get_tree().change_scene_to_file(last_death_scene)
	else:
		get_tree().reload_current_scene()

func mark_cleared(obj_id: String):
	cleared[obj_id] = true

func is_cleared(obj_id: String) -> bool:
	return cleared.get(obj_id, false)

func go_to_level(num: int):
	if level_by_number.has(num):
		get_tree().change_scene_to_file(level_by_number[num])

func on_timer_action(action: int, param: int):
	if param <= 0:
		return
	if action == 2:
		trigger_switch(param, 1)
	elif action == 3:
		# В игре action=3 в основном дёргает свитч, но если numbers
		# совпадает с номером уровня и свитча с таким номером нет — идём дальше.
		if known_switches.has(param) or not level_by_number.has(param):
			trigger_switch(param, 1)
		else:
			go_to_level(param)
	elif action == 1:
		trigger_switch(param, 1)

func next_level():
	var cur = get_tree().current_scene.scene_file_path
	var idx = level_order.find(cur)
	if idx >= 0 and idx + 1 < level_order.size():
		get_tree().change_scene_to_file(level_order[idx + 1])
	elif victory_scene != "":
		get_tree().change_scene_to_file(victory_scene)
	else:
		get_tree().reload_current_scene()


func has_save() -> bool:
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	f.close()
	return true


func save_game() -> bool:
	var cfg = ConfigFile.new()
	var scene = get_tree().current_scene
	if scene == null:
		return false
	cfg.set_value("progress", "scene", scene.scene_file_path)
	cfg.set_value("progress", "hp", hp)
	cfg.set_value("progress", "score", score)
	cfg.set_value("progress", "keys", keys)
	return cfg.save(SAVE_PATH) == OK


func load_game() -> bool:
	if not has_save():
		return false
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	var scene_path = str(cfg.get_value("progress", "scene", ""))
	hp = int(cfg.get_value("progress", "hp", max_hp))
	score = int(cfg.get_value("progress", "score", 0))
	keys = int(cfg.get_value("progress", "keys", 0))
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)
	return true
