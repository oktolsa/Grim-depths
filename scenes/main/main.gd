extends Node2D
class_name Main

## Сцена игрока для спавна
@export var player_scene: PackedScene
## Сцена зелья здоровья
@export var health_potion_scene: PackedScene

## Время игры в секундах
var game_time: float = 0.0
## Флаг активности игры
var is_game_active: bool = true

## Ссылки на узлы
@onready var entities: Node2D = $Entities
@onready var ui_layer: CanvasLayer = $UI
@onready var game_timer: Timer = $GameTimer
@onready var difficulty_timer: Timer = $DifficultyTimer
@onready var time_label: Label = $UI/TopBar/TimeLabel
@onready var difficulty_label: Label = $UI/TopBar/DifficultyLabel
# Label removed
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var experience_bar: ProgressBar = $UI/ExperienceBar
@onready var kill_label: Label = $UI/TopBar/KillLabel
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var result_stats_label: RichTextLabel = $UI/GameOverPanel/VBoxContainer/StatsFrame/ResultStats
@onready var pause_panel: Panel = $UI/PausePanel
@onready var resume_button: Button = $UI/PausePanel/VBoxContainer/ResumeButton
@onready var pause_settings_button: Button = $UI/PausePanel/VBoxContainer/SettingsButton
@onready var pause_main_menu_button: Button = $UI/PausePanel/VBoxContainer/MainMenuButton
@onready var upgrade_panel: Panel = $UI/UpgradePanel
@onready var new_level_label: Label = $UI/UpgradePanel/VBoxContainer/NewLevelLabel
@onready var upgrade_button_1: Button = $UI/UpgradePanel/VBoxContainer/UpgradeButton1
@onready var upgrade_button_2: Button = $UI/UpgradePanel/VBoxContainer/UpgradeButton2
@onready var upgrade_button_3: Button = $UI/UpgradePanel/VBoxContainer/UpgradeButton3
@onready var boss_health_container: VBoxContainer = $UI/BossHealthContainer
@onready var boss_health_bar: ProgressBar = $UI/BossHealthContainer/BossHealthBar
@onready var boss_name_label: Label = $UI/BossHealthContainer/BossNameLabel

var _player: Node2D
var _current_boss: Boss = null
var current_upgrades: Array = []

# Mobile nodes references
var _joystick: Control
var _dash_btn: Button
var _pause_btn: Button

func _ready() -> void:
	_setup_game()
	_connect_signals()
	_spawn_player()
	_spawn_initial_potions(150) # Раскидываем 150 зелий по миру
	_setup_mobile_controls()
	_localize_game_ui()

func _localize_game_ui() -> void:
	# Pause menu
	var pause_lbl = find_child("PauseLabel")
	if pause_lbl: pause_lbl.text = tr("PAUSED")
	if resume_button: resume_button.text = tr("RESUME EXPEDITION")
	if pause_settings_button: pause_settings_button.text = tr("OPTIONS")
	if pause_main_menu_button: pause_main_menu_button.text = tr("RETURN TO HUB")
	
	# Upgrade panel
	var lvl_up_lbl = find_child("LevelUpLabel")
	if lvl_up_lbl: lvl_up_lbl.text = tr("LEVEL UP!")
	var choose_lbl = find_child("ChooseLabel")
	if choose_lbl: choose_lbl.text = tr("Choose your reward:")
	
	# Game Over panel
	var go_lbl = find_child("GameOverLabel")
	if go_lbl: go_lbl.text = tr("THE DEPTHS CLAIMED YOU")
	var restart_btn = find_child("RestartButton")
	if restart_btn: restart_btn.text = tr("RETRY EXPEDITION")
	var mm_btn = find_child("MainMenuButton", true, false) # There are two, find the one in GameOverPanel
	# Specifically target buttons by their full path if possible or context
	$UI/GameOverPanel/VBoxContainer/RestartButton.text = tr("RETRY EXPEDITION")
	$UI/GameOverPanel/VBoxContainer/MainMenuButton.text = tr("RETURN TO HUB")

func _setup_game() -> void:
	get_tree().paused = false
	GameManager.reset()
	game_time = 0.0
	is_game_active = true
	game_over_panel.visible = false
	upgrade_panel.visible = false
	pause_panel.visible = false
	_update_difficulty_display()
	
	game_timer.wait_time = 1.0
	game_timer.timeout.connect(_on_game_timer_timeout)
	game_timer.start()
	
	difficulty_timer.wait_time = 30.0
	difficulty_timer.timeout.connect(_on_difficulty_timer_timeout)
	difficulty_timer.start()

func _connect_signals() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.difficulty_changed.connect(_on_difficulty_changed)
	GameManager.boss_spawned.connect(_on_boss_spawned)
	GameManager.boss_health_changed.connect(_on_boss_health_changed)
	GameManager.boss_died.connect(_on_boss_died)
	GameManager.mobile_settings_changed.connect(_apply_mobile_settings)

func _spawn_player() -> void:
	if not player_scene:
		push_error("Main: player_scene не назначена!")
		return
	
	_player = player_scene.instantiate()
	_player.global_position = Vector2.ZERO
	entities.add_child(_player)
	entities.add_to_group("entity_container")
	
	# Устанавливаем границы камеры для игрока
	_setup_camera_limits(_player)
	_create_world_boundaries()
	_update_background_size()

func _update_background_size() -> void:
	var background = $Background as Sprite2D
	if background:
		var size = GameManager.WORLD_SIZE + 200.0 # Larger margin to prevent edge flicker with zoom
		background.region_rect = Rect2(-size/2, -size/2, size, size)

func _setup_camera_limits(player_node: Player) -> void:
	var camera = player_node.get_node("Camera2D") as Camera2D
	if camera:
		var half_size = GameManager.WORLD_SIZE / 2.0
		camera.limit_left = -half_size
		camera.limit_top = -half_size
		camera.limit_right = half_size
		camera.limit_bottom = half_size

func _create_world_boundaries() -> void:
	var world_size = GameManager.WORLD_SIZE
	var thickness = 200
	var half_size = world_size / 2
	
	var boundaries = StaticBody2D.new()
	boundaries.name = "WorldBoundaries"
	# Слой 1 для препятствий (у игрока маска 1 по умолчанию)
	boundaries.collision_layer = 1
	add_child(boundaries)
	
	var wall_data = [
		{"pos": Vector2(-half_size - thickness/2, 0), "size": Vector2(thickness, world_size + thickness * 2)}, # Left
		{"pos": Vector2(half_size + thickness/2, 0), "size": Vector2(thickness, world_size + thickness * 2)},  # Right
		{"pos": Vector2(0, -half_size - thickness/2), "size": Vector2(world_size + thickness * 2, thickness)}, # Top
		{"pos": Vector2(0, half_size + thickness/2), "size": Vector2(world_size + thickness * 2, thickness)}   # Bottom
	]
	
	for wall in wall_data:
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = wall["size"]
		collision.shape = shape
		collision.position = wall["pos"]
		boundaries.add_child(collision)
	
	# Подключаем сигналы игрока
	if _player.has_signal("died"):
		_player.died.connect(_on_player_died)
	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_player_health_changed)
		# Инициализируем HP бар
		health_bar.max_value = _player.max_hp
		health_bar.value = _player.hp
	if _player.has_signal("experience_changed"):
		_player.experience_changed.connect(_on_player_experience_changed)
		# Инициализируем EXP бар
		experience_bar.max_value = _player.target_exp
		experience_bar.value = _player.current_exp
	if _player.has_signal("level_up"):
		_player.level_up.connect(_on_player_level_up)
	
	# Подключаем кнопки апгрейдов
	_connect_upgrade_buttons()
	_setup_ui_animations()

func _setup_ui_animations() -> void:
	var buttons = [upgrade_button_1, upgrade_button_2, upgrade_button_3]
	var go_buttons = [$UI/GameOverPanel/VBoxContainer/RestartButton, $UI/GameOverPanel/VBoxContainer/MainMenuButton, resume_button, pause_settings_button, pause_main_menu_button]
	
	for btn in buttons + go_buttons:
		if btn:
			btn.focus_mode = Control.FOCUS_NONE
			btn.action_mode = Button.ACTION_MODE_BUTTON_PRESS
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.mouse_entered.connect(_on_button_hover.bind(btn))
			btn.mouse_exited.connect(_on_button_unhover.bind(btn))
			btn.pressed.connect(func(): if btn.is_inside_tree(): btn.release_focus())
			# Set pivot to center for better scaling
			btn.pivot_offset = btn.size / 2.0
			btn.item_rect_changed.connect(func(): btn.pivot_offset = btn.size / 2.0)

func _on_button_hover(btn: Button) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)

func _on_button_unhover(btn: Button) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _on_game_timer_timeout() -> void:
	if not is_game_active:
		return
	
	game_time += 1.0
	_update_time_display()
	_update_kill_display()

func _update_time_display() -> void:
	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	time_label.text = "%s %02d:%02d" % [tr("Time:"), minutes, seconds]

func _update_kill_display() -> void:
	if kill_label:
		kill_label.text = "%s %d" % [tr("Kills:"), GameManager.kills]

func _update_difficulty_display() -> void:
	difficulty_label.text = tr("Level %d") % GameManager.difficulty_level

func _on_difficulty_timer_timeout() -> void:
	if not is_game_active:
		return
	
	GameManager.increase_difficulty()

func _on_difficulty_changed(_level: int) -> void:
	_update_difficulty_display()

func _on_player_health_changed(current_hp: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(health_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_player_experience_changed(current_exp: int, target_exp: int) -> void:
	experience_bar.max_value = target_exp
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(experience_bar, "value", float(current_exp), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_player_level_up(new_level: int) -> void:
	_show_upgrade_panel(new_level)

func _update_player_level_display() -> void:
	pass # Deprecated

func _on_boss_spawned(boss_name: String, max_hp: float) -> void:
	# Если уже есть босс, не перезаписываем UI (но новый босс всё равно заспавнится)
	if _current_boss and is_instance_valid(_current_boss):
		return
		
	boss_name_label.text = boss_name
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = max_hp
	boss_health_container.visible = true

func register_active_boss(boss: Boss):
	_current_boss = boss

func _on_boss_health_changed(current_hp: float, max_hp: float) -> void:
	if boss_health_container.visible:
		update_boss_health_ui(current_hp, max_hp)

func _on_boss_died() -> void:
	# Ждем немного перед скрытием UI (эффект смерти)
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(hide_boss_ui)

var _boss_health_tween: Tween

func update_boss_health_ui(current_hp: float, max_hp: float):
	boss_health_bar.max_value = max_hp
	if _boss_health_tween:
		_boss_health_tween.kill()
	_boss_health_tween = create_tween()
	_boss_health_tween.tween_property(boss_health_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func hide_boss_ui():
	boss_health_container.visible = false
	_current_boss = null

func _show_upgrade_panel(new_level: int) -> void:
	new_level_label.text = tr("Level %d") % new_level
	upgrade_panel.visible = true
	get_tree().paused = true
	
	var upgrades = GameManager.get_random_upgrades(3)
	current_upgrades = upgrades
	
	if upgrades.size() > 0:
		upgrade_button_1.text = "%s\n%s" % [tr(upgrades[0]["name"]), tr(upgrades[0]["description"])]
		upgrade_button_1.visible = true
	else:
		upgrade_button_1.visible = false
		
	if upgrades.size() > 1:
		upgrade_button_2.text = "%s\n%s" % [tr(upgrades[1]["name"]), tr(upgrades[1]["description"])]
		upgrade_button_2.visible = true
	else:
		upgrade_button_2.visible = false
		
	if upgrades.size() > 2:
		upgrade_button_3.text = "%s\n%s" % [tr(upgrades[2]["name"]), tr(upgrades[2]["description"])]
		upgrade_button_3.visible = true
	else:
		upgrade_button_3.visible = false

func _connect_upgrade_buttons() -> void:
	upgrade_button_1.pressed.connect(_on_upgrade_selected.bind(0))
	upgrade_button_2.pressed.connect(_on_upgrade_selected.bind(1))
	upgrade_button_3.pressed.connect(_on_upgrade_selected.bind(2))

func _on_upgrade_selected(index: int) -> void:
	if index < current_upgrades.size():
		var upgrade = current_upgrades[index]
		GameManager.apply_upgrade(upgrade)
		print("Applied upgrade: ", upgrade["name"])
	
	upgrade_panel.visible = false
	get_tree().paused = false

func _on_player_died() -> void:
	GameManager.trigger_game_over()

func _on_game_over() -> void:
	is_game_active = false
	# Статистика
	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	var time_str = "%02d:%02d" % [minutes, seconds]
	var player_lvl = _player.level if _player else 1
	var kills_count = GameManager.kills
	
	# Красивое форматирование результатов (используем BBCode)
	result_stats_label.text = "[center][font_size=28][b]%s[/b][/font_size]\n\n" % tr("RESULTS:")
	result_stats_label.text += "[color=#aaaaaa]%s[/color] [b]%s[/b]\n" % [tr("Survival Time:"), time_str]
	result_stats_label.text += "[color=#aaaaaa]%s[/color] [b]%d[/b]\n" % [tr("Player Level:"), player_lvl]
	result_stats_label.text += "[color=#aaaaaa]%s[/color] [b]%d[/b][/center]" % [tr("Total Kills:"), kills_count]
	
	# Стилизация и анимация
	_style_premium_panel(game_over_panel)
	game_over_panel.modulate.a = 0.0
	game_over_panel.scale = Vector2(0.9, 0.9)
	game_over_panel.visible = true
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(game_over_panel, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(game_over_panel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	get_tree().paused = true

func _style_premium_panel(panel: Panel) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9) # Dark blue-grey
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.8, 0.6, 0.2, 0.8) # Gold border
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 30
	panel.add_theme_stylebox_override("panel", style)

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _setup_mobile_controls() -> void:
	# Скрываем мобильное управление на ПК, если не включена эмуляция
	var is_mobile = OS.has_feature("mobile") or ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse")
	if not is_mobile:
		return

	# Добавляем джойстик
	_joystick = Control.new()
	_joystick.set_script(load("res://scenes/ui/joystick.gd"))
	_joystick.custom_minimum_size = Vector2(200, 200)
	_joystick.size = Vector2(200, 200)
	ui_layer.add_child(_joystick)
	
	# Добавляем кнопку рывка (Dash)
	_dash_btn = Button.new()
	_dash_btn.text = "DASH"
	_dash_btn.name = "MobileDashButton"
	_dash_btn.custom_minimum_size = Vector2(120, 120)
	_dash_btn.size = Vector2(120, 120)
	_dash_btn.focus_mode = Control.FOCUS_NONE
	_dash_btn.action_mode = Button.ACTION_MODE_BUTTON_PRESS
	
	# Стилизация кнопки
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.2)
	style.corner_radius_top_left = 60
	style.corner_radius_top_right = 60
	style.corner_radius_bottom_left = 60
	style.corner_radius_bottom_right = 60
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(1, 1, 1, 0.4)
	
	var style_pressed = style.duplicate()
	style_pressed.bg_color = Color(1, 1, 1, 0.4)
	
	_dash_btn.add_theme_stylebox_override("normal", style)
	_dash_btn.add_theme_stylebox_override("hover", style)
	_dash_btn.add_theme_stylebox_override("pressed", style_pressed)
	_dash_btn.add_theme_color_override("font_color", Color.WHITE)
	_dash_btn.add_theme_font_size_override("font_size", 24)
	
	_dash_btn.pivot_offset = Vector2(60, 60)
	_dash_btn.pressed.connect(func(): 
		var tween = create_tween()
		tween.tween_property(_dash_btn, "scale", Vector2(0.9, 0.9) * GameManager.mobile_joystick_scale, 0.05)
		tween.tween_property(_dash_btn, "scale", Vector2(1.0, 1.0) * GameManager.mobile_joystick_scale, 0.05)
		
		Input.action_press("ui_accept")
		await get_tree().create_timer(0.1).timeout
		Input.action_release("ui_accept")
	)
	ui_layer.add_child(_dash_btn)
	
	# Добавляем кнопку паузы
	_pause_btn = Button.new()
	_pause_btn.text = "||"
	_pause_btn.name = "MobilePauseButton"
	_pause_btn.custom_minimum_size = Vector2(80, 80)
	_pause_btn.size = Vector2(80, 80)
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.action_mode = Button.ACTION_MODE_BUTTON_PRESS
	_pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_pause_btn.pressed.connect(func(): _toggle_pause())
	ui_layer.add_child(_pause_btn)
	
	_apply_mobile_settings()

func _apply_mobile_settings() -> void:
	if not _joystick or not is_instance_valid(_joystick):
		return
		
	var viewport_size = get_viewport_rect().size
	var is_swapped = GameManager.mobile_swap_controls
	var opacity = GameManager.mobile_controls_opacity
	var scale = GameManager.mobile_joystick_scale
	
	# Position Joystick
	if is_swapped:
		# Swapped: Joystick is on the RIGHT
		_joystick.position = Vector2(viewport_size.x - 300 * scale, viewport_size.y - 300 * scale)
	else:
		# Normal: Joystick is on the LEFT
		_joystick.position = Vector2(100, viewport_size.y - 300 * scale)
	
	_joystick.scale = Vector2(scale, scale)
	_joystick.modulate.a = opacity
	
	# Position Dash Button
	if is_swapped:
		# Swapped: Dash is on the LEFT
		_dash_btn.position = Vector2(100, viewport_size.y - 250 * scale)
	else:
		# Normal: Dash is on the RIGHT
		_dash_btn.position = Vector2(viewport_size.x - 220, viewport_size.y - 250 * scale)
		
	_dash_btn.scale = Vector2(scale, scale)
	_dash_btn.modulate.a = opacity
	
	# Position Pause Button (usually stay top right)
	_pause_btn.position = Vector2(viewport_size.x - 120, 30)
	_pause_btn.modulate.a = opacity

func _unhandled_input(event: InputEvent) -> void:
	var is_escape = false
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE:
		is_escape = true
	elif event.is_action_pressed("ui_cancel"):
		is_escape = true

	if is_escape and is_game_active and not upgrade_panel.visible and not game_over_panel.visible:
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if get_tree().paused and pause_panel.visible:
		# Resume
		get_tree().paused = false
		pause_panel.visible = false
	elif not get_tree().paused:
		# Pause
		get_tree().paused = true
		pause_panel.visible = true

func resume_game() -> void:
	get_tree().paused = false
	pause_panel.visible = false

func open_settings() -> void:
	var settings = load("res://scenes/ui/settings_menu.tscn").instantiate()
	pause_panel.visible = false
	settings.back_pressed.connect(func(): if get_tree().paused: pause_panel.visible = true)
	ui_layer.add_child(settings)

## Получить контейнер для динамических объектов
func get_entities_container() -> Node2D:
	return entities

## Получить ссылку на игрока
func get_player() -> Node2D:
	return _player

func _spawn_initial_potions(count: int) -> void:
	if not health_potion_scene:
		print("Health potion scene not assigned in Main!")
		return
		
	var half_size = GameManager.WORLD_SIZE / 2.0
	# Оставляем отступ от краев
	var margin = 200.0
	var spawn_range = half_size - margin
	
	for i in range(count):
		var potion = health_potion_scene.instantiate()
		var random_pos = Vector2(
			randf_range(-spawn_range, spawn_range),
			randf_range(-spawn_range, spawn_range)
		)
		potion.global_position = random_pos
		entities.add_child(potion)
