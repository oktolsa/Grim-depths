extends Control

## Виртуальный джойстик для управления на мобильных устройствах

@export var joystick_radius: float = 100.0
@export var stick_radius: float = 40.0

var _is_dragging: bool = false
var _joystick_center: Vector2
var _stick_pos: Vector2 = Vector2.ZERO
var _touch_index: int = -1

func _ready() -> void:
	# Скрываем на ПК, если не включена эмуляция
	if not OS.has_feature("mobile") and not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"):
		visible = false
	_stick_pos = Vector2.ZERO
	queue_redraw()
	# Пересчитываем центр после первого кадра
	await get_tree().process_frame
	_joystick_center = global_position + size / 2.0

func _notification(what: int) -> void:
	# Обновляем центр только при изменении размера контрола
	if what == NOTIFICATION_RESIZED:
		_joystick_center = global_position + size / 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# Пересчитываем центр при каждом касании — позиция может сместиться
			_joystick_center = global_position + size / 2.0
			var dist = (event.position - _joystick_center).length()
			if dist < joystick_radius * 2.0: # Увеличенная зона захвата
				_is_dragging = true
				_touch_index = event.index
				_update_stick(event.position)
		elif event.index == _touch_index:
			_is_dragging = false
			_touch_index = -1
			_stick_pos = Vector2.ZERO
			_update_input_actions(Vector2.ZERO)
			queue_redraw()
			
	elif event is InputEventScreenDrag and _is_dragging and event.index == _touch_index:
		_update_stick(event.position)

func _update_stick(pos: Vector2) -> void:
	var diff = pos - _joystick_center
	var dist = diff.length()
	
	# Мертвая зона (deadzone), чтобы не было рывков в центре
	var deadzone = 10.0
	if dist < deadzone:
		_stick_pos = Vector2.ZERO
		_update_input_actions(Vector2.ZERO)
	else:
		if dist > joystick_radius:
			_stick_pos = diff.normalized() * joystick_radius
		else:
			_stick_pos = diff
		
		# Пересчитываем позицию с учетом мертвой зоны для плавного старта
		var normalized_pos = (_stick_pos.length() - deadzone) / (joystick_radius - deadzone)
		normalized_pos = max(0, normalized_pos)
		_update_input_actions(_stick_pos.normalized() * normalized_pos)
	
	queue_redraw()

func _update_input_actions(dir: Vector2) -> void:
	# Используем силу нажатия (strength) для аналогового управления
	# Это избавляет от рывков и позволяет двигаться медленнее или быстрее
	
	# Горизонтальное движение
	if dir.x > 0:
		Input.action_press("move_right", dir.x)
		Input.action_release("move_left")
	elif dir.x < 0:
		Input.action_press("move_left", -dir.x)
		Input.action_release("move_right")
	else:
		Input.action_release("move_right")
		Input.action_release("move_left")
		
	# Вертикальное движение
	if dir.y > 0:
		Input.action_press("move_down", dir.y)
		Input.action_release("move_up")
	elif dir.y < 0:
		Input.action_press("move_up", -dir.y)
		Input.action_release("move_down")
	else:
		Input.action_release("move_down")
		Input.action_release("move_up")

func _handle_action(action: String, is_pressed: bool) -> void:
	# Этот метод больше не нужен, так как мы обрабатываем всё в _update_input_actions
	pass

func _draw() -> void:
	# Рисуем основу джойстика
	draw_circle(Vector2.ZERO + size/2, joystick_radius, Color(1, 1, 1, 0.2))
	# Рисуем сам стик
	draw_circle(_stick_pos + size/2, stick_radius, Color(1, 1, 1, 0.5))
