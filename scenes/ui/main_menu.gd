extends Control
class_name MainMenu

@onready var currency_label: Label = %CurrencyLabel

func _ready() -> void:
	update_currency_display()
	
	if GameManager.has_signal("currency_changed"):
		GameManager.currency_changed.connect(_on_currency_changed)
	
	_setup_button_animations()

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

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_talents_pressed() -> void:
	print("Talents Menu - Not yet implemented")

func _on_settings_pressed() -> void:
	var settings = load("res://scenes/ui/settings_menu.tscn").instantiate()
	add_child(settings)

func _on_exit_pressed() -> void:
	get_tree().quit()
