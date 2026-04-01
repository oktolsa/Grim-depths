extends Node
## Унифицированный менеджер визуальных эффектов интерфейса

# Константы стиля
const COLOR_BG_DARK = Color(0.04, 0.02, 0.02, 0.95) # Почти черный для глубины
const COLOR_BORDER_RED = Color(0.8, 0.1, 0.0, 1.0) # Ярко-красный
const COLOR_BORDER_FIERY = Color(1.0, 0.4, 0.1, 1.0) # Огненно-оранжевый
const COLOR_GLOW_FIERY = Color(1.0, 0.2, 0.0, 0.3) # Красное свечение
const COLOR_TEXT_FIERY = Color(1.0, 0.8, 0.3, 1.0) # Огненный текст

func _ready() -> void:
	pass

## Применить "Адский" стиль к панели
func style_premium_panel(panel: Panel, is_fiery: bool = false) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_DARK
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = COLOR_BORDER_FIERY if is_fiery else COLOR_BORDER_RED
	style.corner_radius_top_left = 12 # Более острые углы
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = COLOR_GLOW_FIERY
	style.shadow_size = 25 if is_fiery else 15
	
	panel.add_theme_stylebox_override("panel", style)

## Настроить кнопку (анимации, курсор, фокус)
func setup_button(btn: Button) -> void:
	if not btn: return
	
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pivot_offset = btn.size / 2.0
	
	# Обновляем pivot при изменении размера
	if not btn.item_rect_changed.is_connected(_on_btn_rect_changed.bind(btn)):
		btn.item_rect_changed.connect(_on_btn_rect_changed.bind(btn))
		
	# Анимации наведения (Масштаб + Свечение текста)
	if not btn.mouse_entered.is_connected(_on_btn_hover.bind(btn)):
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
	if not btn.mouse_exited.is_connected(_on_btn_unhover.bind(btn)):
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))
		
	# Анимация нажатия
	if not btn.button_down.is_connected(_on_btn_down.bind(btn)):
		btn.button_down.connect(_on_btn_down.bind(btn))
	if not btn.button_up.is_connected(_on_btn_up.bind(btn)):
		btn.button_up.connect(_on_btn_up.bind(btn))

func _on_btn_rect_changed(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0

func _on_btn_hover(btn: Button) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)
	# Добавляем оранжевый оттенок тексту при наведении (избегаем Nil ошибки через .from)
	var current_hover_color = btn.get_theme_color("font_hover_color")
	tween.tween_property(btn, "theme_override_colors/font_hover_color", Color(1, 0.6, 0.2), 0.1).from(current_hover_color)


func _on_btn_unhover(btn: Button) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	# Возвращаем исходный цвет (безопасно через .from)
	var target_color = btn.get_theme_color("font_hover_color") 
	tween.tween_property(btn, "theme_override_colors/font_hover_color", target_color, 0.1).from(Color(1, 0.6, 0.2))


func _on_btn_down(btn: Button) -> void:
	btn.scale = Vector2(0.95, 0.95)

func _on_btn_up(btn: Button) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.05).set_trans(Tween.TRANS_SINE)

## Плавное появление узла
func fade_in(node: CanvasItem, duration: float = 0.4, delay: float = 0.0) -> void:
	node.modulate.a = 0.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if delay > 0:
		tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE)

## Анимация "вплывания" снизу
func slide_up(node: Control, distance: float = 30.0, duration: float = 0.5) -> void:
	var target_pos = node.position
	node.position.y += distance
	node.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "position:y", target_pos.y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.8).set_trans(Tween.TRANS_SINE)

## Анимация огня для текста заголовка
func animate_fiery_title(label: Label) -> void:
	if not label: return
	
	# Эффект пульсации цвета и легкого дрожания (как пламя)
	var tween = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(label, "theme_override_colors/font_color", COLOR_TEXT_FIERY, 0.8).from(COLOR_BORDER_FIERY)
	tween.tween_property(label, "theme_override_colors/font_color", COLOR_BORDER_FIERY, 0.8)
	
	# Добавим легкое покачивание
	var shake_tween = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake_tween.tween_property(label, "position:y", label.position.y - 2, 0.4).set_trans(Tween.TRANS_SINE)
	shake_tween.tween_property(label, "position:y", label.position.y + 2, 0.4).set_trans(Tween.TRANS_SINE)
	shake_tween.parallel().tween_property(label, "scale", Vector2(1.02, 0.98), 0.5).set_trans(Tween.TRANS_SINE)
	shake_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
