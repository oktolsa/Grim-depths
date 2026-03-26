extends Control
class_name MainMenu

@onready var currency_label: Label = %CurrencyLabel
@onready var menu_box: Panel = $MenuBox
@onready var record_frame: PanelContainer = %RecordFrame
@onready var record_stats: RichTextLabel = %RecordStats

func _ready() -> void:
	update_currency_display()
	
	if GameManager.has_signal("currency_changed"):
		GameManager.currency_changed.connect(_on_currency_changed)
	
	_setup_button_animations()
	_localize_ui()
	_style_main_menu()
	update_record_display()
	_animate_entrance()
	
	if GameManager.has_signal("mobile_settings_changed"):
		GameManager.mobile_settings_changed.connect(_localize_ui)

func _localize_ui() -> void:
	# Localize Title
	var title = find_child("TitleLabel")
	if title: title.text = tr("GRIM DEPTHS")
	
	# Localize Buttons
	var play_btn = find_child("PlayButton")
	if play_btn: play_btn.text = tr("START EXPEDITION")
	
	var talents_btn = find_child("TalentsButton")
	if talents_btn: talents_btn.text = tr("CHARACTER TALENTS")
	
	var settings_btn = find_child("SettingsButton")
	if settings_btn: settings_btn.text = tr("OPTIONS")
	
	var exit_btn = find_child("ExitButton")
	if exit_btn: exit_btn.text = tr("EXIT TO DESKTOP")

func _setup_button_animations() -> void:
	var buttons = find_children("*", "Button", true)
	for btn in buttons:
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
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)

func _on_button_unhover(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func update_currency_display() -> void:

	if currency_label:
		currency_label.text = tr("Soul Shards:") + " %d" % GameManager.soul_shards

func _on_currency_changed(new_amount: int) -> void:
	update_currency_display()

func _style_main_menu() -> void:
	# Menu Box Style
	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.08, 0.05, 0.08, 0.85)
	box_style.border_width_left = 4
	box_style.border_width_top = 4
	box_style.border_width_right = 4
	box_style.border_width_bottom = 4
	box_style.border_color = Color(0.6, 0.1, 0.1, 0.6) # Darker red border
	box_style.corner_radius_top_left = 30
	box_style.corner_radius_top_right = 30
	box_style.corner_radius_bottom_left = 30
	box_style.corner_radius_bottom_right = 30
	box_style.shadow_color = Color(1.0, 0, 0, 0.1) # Subtle red glow
	box_style.shadow_size = 25
	menu_box.add_theme_stylebox_override("panel", box_style)
	
	# Record Frame Style
	var rec_style = StyleBoxFlat.new()
	rec_style.bg_color = Color(0.12, 0.1, 0.15, 0.7)
	rec_style.border_width_left = 3
	rec_style.border_width_top = 3
	rec_style.border_width_right = 3
	rec_style.border_width_bottom = 3
	rec_style.border_color = Color(0.8, 0.6, 0.2, 0.6) # Gold border
	rec_style.corner_radius_top_left = 12
	rec_style.corner_radius_top_right = 12
	rec_style.corner_radius_bottom_left = 12
	rec_style.corner_radius_bottom_right = 12
	rec_style.content_margin_left = 15
	rec_style.content_margin_top = 10
	rec_style.content_margin_right = 15
	rec_style.content_margin_bottom = 10
	record_frame.add_theme_stylebox_override("panel", rec_style)
	
	# Currency Style (Optional background for the label)
	# Maybe add a small panel for currency later if needed

func _animate_entrance() -> void:
	# Subtle fade-in and slide-up for the menu
	menu_box.modulate.a = 0.0
	menu_box.position.y += 30
	record_frame.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(menu_box, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(menu_box, "position:y", menu_box.position.y - 30, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(record_frame, "modulate:a", 1.0, 0.8).set_delay(0.3)

func update_record_display() -> void:
	if record_stats:
		var minutes := int(GameManager.max_time) / 60
		var seconds := int(GameManager.max_time) % 60
		var time_str = "%02d:%02d" % [minutes, seconds]
		
		record_stats.text = "[center][color=#aaaaaa]%s[/color] [b]%d[/b]\n" % [tr("Kills:"), GameManager.max_kills]
		record_stats.text += "[color=#aaaaaa]%s[/color] [b]%s[/b][/center]" % [tr("Time:"), time_str]
	
	var best_lbl = record_frame.find_child("BestLabel")
	if best_lbl: best_lbl.text = tr("BEST RECORD:")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_talents_pressed() -> void:
	print("Talents Menu - Not yet implemented")

func _on_settings_pressed() -> void:
	var settings = load("res://scenes/ui/settings_menu.tscn").instantiate()
	menu_box.visible = false
	record_frame.visible = false
	settings.tree_exited.connect(func(): 
		menu_box.visible = true
		record_frame.visible = true
	)
	add_child(settings)

func _on_exit_pressed() -> void:
	get_tree().quit()
