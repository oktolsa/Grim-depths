extends Panel

func _unhandled_input(event: InputEvent) -> void:
	var is_escape = false
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE:
		is_escape = true
	elif event.is_action_pressed("ui_cancel"):
		is_escape = true

	if is_escape and visible:
		var main_node = get_parent().get_parent()
		if main_node and main_node.has_method("_toggle_pause"):
			main_node._toggle_pause()
			get_viewport().set_input_as_handled()
