extends Control

var _dragging_node: Control = null
var _offset: Vector2

var joystick: Control
var dash_btn: Control
var save_btn: Button
var reset_btn: Button

func _ready() -> void:
	# Keep working even when the game is paused
	process_mode = PROCESS_MODE_ALWAYS
	
	# Small delay to ensure children are added in code
	await get_tree().process_frame
	
	# Safely find nodes
	joystick = find_child("Joystick", true, false)
	dash_btn = find_child("Dash", true, false)
	save_btn = find_child("SaveButton", true, false)
	reset_btn = find_child("ResetButton", true, false)
	
	# Load positions from GameManager
	var scale = GameManager.mobile_joystick_scale
	var opacity = GameManager.mobile_controls_opacity
	var viewport_size = get_viewport_rect().size
	
	# Current Joystick
	if joystick:
		if GameManager.mobile_joystick_pos != Vector2(-1, -1):
			joystick.position = GameManager.mobile_joystick_pos
		else:
			if GameManager.mobile_swap_controls:
				joystick.position = Vector2(viewport_size.x - 300 * scale, viewport_size.y - 300 * scale)
			else:
				joystick.position = Vector2(100, viewport_size.y - 300 * scale)
		
		joystick.scale = Vector2(scale, scale)
		joystick.modulate.a = opacity
		_setup_draggable(joystick)
	
	# Current Dash
	if dash_btn:
		if GameManager.mobile_dash_pos != Vector2(-1, -1):
			dash_btn.position = GameManager.mobile_dash_pos
		else:
			if GameManager.mobile_swap_controls:
				dash_btn.position = Vector2(100, viewport_size.y - 250 * scale)
			else:
				dash_btn.position = Vector2(viewport_size.x - 220 * scale, viewport_size.y - 250 * scale)
		
		dash_btn.scale = Vector2(scale, scale)
		dash_btn.modulate.a = opacity
		_setup_draggable(dash_btn)
	
	# Connect buttons
	if save_btn: save_btn.pressed.connect(_on_save_pressed)
	if reset_btn: reset_btn.pressed.connect(_on_reset_pressed)

func _setup_draggable(node: Control) -> void:
	node.gui_input.connect(func(event):
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			if event.pressed:
				_dragging_node = node
			else:
				_dragging_node = null
		elif event is InputEventScreenDrag or (event is InputEventMouseMotion):
			if _dragging_node == node:
				node.position += event.relative
	)

func _on_save_pressed() -> void:
	if joystick and dash_btn:
		GameManager.update_mobile_settings(
			GameManager.mobile_swap_controls, 
			GameManager.mobile_controls_opacity, 
			GameManager.mobile_joystick_scale,
			joystick.position,
			dash_btn.position
		)
	queue_free()

func _on_reset_pressed() -> void:
	GameManager.mobile_joystick_pos = Vector2(-1, -1)
	GameManager.mobile_dash_pos = Vector2(-1, -1)
	GameManager.save_game()
	# Just reload visual state
	var viewport_size = get_viewport_rect().size
	var scale = GameManager.mobile_joystick_scale
	if joystick:
		if GameManager.mobile_swap_controls:
			joystick.position = Vector2(viewport_size.x - 300 * scale, viewport_size.y - 300 * scale)
		else:
			joystick.position = Vector2(100, viewport_size.y - 300 * scale)
	if dash_btn:
		if GameManager.mobile_swap_controls:
			dash_btn.position = Vector2(100, viewport_size.y - 250 * scale)
		else:
			dash_btn.position = Vector2(viewport_size.x - 220 * scale, viewport_size.y - 250 * scale)
