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
	
	_joystick_center = global_position + size / 2.0
	# Сброс позиции в центр
	_stick_pos = Vector2.ZERO
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
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
	
	if dist > joystick_radius:
		_stick_pos = diff.normalized() * joystick_radius
	else:
		_stick_pos = diff
		
	_update_input_actions(_stick_pos / joystick_radius)
	queue_redraw()

func _update_input_actions(dir: Vector2) -> void:
	# Превращаем вектор в нажатия кнопок для совместимости с существующей логикой
	# Мы используем Input.action_press/release
	
	# Порог срабатывания
	var threshold = 0.2
	
	_handle_action("move_right", dir.x > threshold)
	_handle_action("move_left", dir.x < -threshold)
	_handle_action("move_down", dir.y > threshold)
	_handle_action("move_up", dir.y < -threshold)

func _handle_action(action: String, is_pressed: bool) -> void:
	if is_pressed:
		Input.action_press(action, 1.0)
	else:
		Input.action_release(action)

func _draw() -> void:
	# Рисуем основу джойстика
	draw_circle(Vector2.ZERO + size/2, joystick_radius, Color(1, 1, 1, 0.2))
	# Рисуем сам стик
	draw_circle(_stick_pos + size/2, stick_radius, Color(1, 1, 1, 0.5))
