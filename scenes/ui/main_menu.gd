extends Control
class_name MainMenu

@onready var currency_label: Label = %CurrencyLabel
@onready var menu_box: Control = $MenuBox
@onready var play_button: Button = $MenuBox/ContentContainer/ButtonsContainer/PlayButton
@onready var talents_button: Button = $MenuBox/ContentContainer/ButtonsContainer/TalentsButton
@onready var statistics_button: Button = $MenuBox/ContentContainer/ButtonsContainer/StatisticsButton
@onready var settings_button: Button = $MenuBox/ContentContainer/ButtonsContainer/SettingsButton
@onready var exit_button: Button = $MenuBox/ContentContainer/ButtonsContainer/ExitButton

@onready var video_player_origin: VideoStreamPlayer = $VideoPlayerOrigin
@onready var video_player_after: VideoStreamPlayer = $VideoPlayerAfter

func _ready() -> void:
	update_currency_display()
	
	if GameManager.has_signal("currency_changed"):
		GameManager.currency_changed.connect(_on_currency_changed)
	
	_setup_ui()
	_localize_ui()
	_animate_entrance()
	
	UIEffects.animate_fiery_title($MenuBox/ContentContainer/TitleLabel)

	
	if GameManager.has_signal("mobile_settings_changed"):
		GameManager.mobile_settings_changed.connect(_localize_ui)
		
	_setup_videos()

func _setup_videos() -> void:
	# Godot reliably plays only .ogv (Ogg Theora) out of the box without plugins
	video_player_origin.stream = load("res://Assets/0402/0402.ogv")
	# video_player_after.stream = load("res://Assets/afterback.ogv") # If there's a second one
	
	# Since there's one looping file now, we just loop it
	if video_player_origin.stream:
		video_player_origin.finished.connect(_on_video_origin_finished)
		video_player_origin.play()
		video_player_origin.visible = true
	video_player_after.visible = false

func _on_video_origin_finished() -> void:
	# Seamlessly restart the video
	video_player_origin.play()

func _setup_ui() -> void:
	var empty_style = StyleBoxEmpty.new()
	var buttons = [play_button, talents_button, statistics_button, settings_button, exit_button]
	for btn in buttons:
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("hover", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		btn.add_theme_stylebox_override("focus", empty_style)
		btn.add_theme_font_size_override("font_size", 42)
		btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.5, 0.5, 0.5))
		
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if not btn.item_rect_changed.is_connected(_on_btn_rect_changed.bind(btn)):
			btn.item_rect_changed.connect(_on_btn_rect_changed.bind(btn))
			
		if not btn.mouse_entered.is_connected(_on_btn_hover.bind(btn)):
			btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		if not btn.mouse_exited.is_connected(_on_btn_unhover.bind(btn)):
			btn.mouse_exited.connect(_on_btn_unhover.bind(btn))
		if not btn.button_down.is_connected(_on_btn_down.bind(btn)):
			btn.button_down.connect(_on_btn_down.bind(btn))
		if not btn.button_up.is_connected(_on_btn_up.bind(btn)):
			btn.button_up.connect(_on_btn_up.bind(btn))

func _on_btn_rect_changed(btn: Button) -> void:
	btn.pivot_offset = Vector2(btn.size.x / 2.0, btn.size.y / 2.0) # Для выравнивания по центру лучше так, но если выровнено по левому, то (0, y/2)
	# Оставим по центру, потому что кнопки изначально по центру
	btn.pivot_offset = Vector2(0, btn.size.y / 2.0) if btn.alignment == HORIZONTAL_ALIGNMENT_LEFT else Vector2(btn.size.x / 2.0, btn.size.y / 2.0)

func _on_btn_hover(btn: Button) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_SINE)

func _on_btn_unhover(btn: Button) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)

func _on_btn_down(btn: Button) -> void:
	btn.scale = Vector2(0.95, 0.95)

func _on_btn_up(btn: Button) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.05).set_trans(Tween.TRANS_SINE)

func _localize_ui() -> void:
	var title = find_child("TitleLabel")
	if title: title.text = tr("GRIM DEPTHS")
	
	play_button.text = tr("START EXPEDITION")
	talents_button.text = tr("CHARACTER TALENTS")
	statistics_button.text = tr("STATISTICS")
	settings_button.text = tr("OPTIONS")
	exit_button.text = tr("EXIT TO DESKTOP")

func update_currency_display() -> void:
	if currency_label:
		currency_label.text = tr("Soul Shards:") + " %d" % GameManager.soul_shards

func _on_currency_changed(new_amount: int) -> void:
	update_currency_display()

func _animate_entrance() -> void:
	UIEffects.fade_in(menu_box)
	UIEffects.slide_up(menu_box)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_talents_pressed() -> void:
	print("Talents Menu - Not yet implemented")

func _on_statistics_pressed() -> void:
	var stats = load("res://scenes/ui/statistics_menu.tscn").instantiate()
	menu_box.visible = false
	stats.back_pressed.connect(func():
		menu_box.visible = true
	)
	add_child(stats)


func _on_settings_pressed() -> void:
	var settings = load("res://scenes/ui/settings_menu.tscn").instantiate()
	menu_box.visible = false
	settings.back_pressed.connect(func(): 
		menu_box.visible = true
	)
	add_child(settings)


func _on_exit_pressed() -> void:
	get_tree().quit()
