extends Control
class_name SettingsMenu

signal back_pressed

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var lang_option: OptionButton = %LangOptionButton
@onready var swap_button: CheckButton = %SwapButton
@onready var opacity_slider: HSlider = %OpacitySlider
@onready var joystick_slider: HSlider = %JoystickSlider

func _ready() -> void:
	_setup_ui()
	_connect_signals()

func _connect_signals() -> void:
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if lang_option:
		lang_option.item_selected.connect(_on_lang_selected)
	if swap_button:
		swap_button.toggled.connect(_on_mobile_settings_changed)
	if opacity_slider:
		opacity_slider.value_changed.connect(_on_mobile_settings_changed)
	if joystick_slider:
		joystick_slider.value_changed.connect(_on_mobile_settings_changed)
	
	# Add custom layout button programmatically
	var customize_btn = Button.new()
	customize_btn.text = tr("CUSTOMIZE LAYOUT")
	customize_btn.name = "CustomizeLayoutButton"
	customize_btn.pressed.connect(_on_customize_layout_pressed)
	
	if joystick_slider:
		var parent = joystick_slider.get_parent()
		if parent:
			parent.add_child(customize_btn)
			customize_btn.custom_minimum_size = Vector2(0, 50)
			# Add margin for better layout if it's a VBox
			if parent is VBoxContainer:
				customize_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UIEffects.setup_button(customize_btn)


func _setup_ui() -> void:
	# Блокируем сигналы чтобы избежать рекурсии при заполнении
	var old_block = is_blocking_signals()
	set_block_signals(true)
	
	# Громкость музыки и звуков
	if music_slider:
		music_slider.value = AudioManager.get_music_volume() if get_node_or_null("/root/AudioManager") else GameManager.audio_music_volume
	if sfx_slider:
		sfx_slider.value = AudioManager.get_sfx_volume() if get_node_or_null("/root/AudioManager") else GameManager.audio_sfx_volume
	
	# Мобильные элементы управления
	if swap_button:
		swap_button.button_pressed = GameManager.mobile_swap_controls
	if opacity_slider:
		opacity_slider.value = GameManager.mobile_controls_opacity
	if joystick_slider:
		joystick_slider.value = GameManager.mobile_joystick_scale

	# Язык — только текст, без иконок-картинок
	if lang_option:
		lang_option.clear()
		lang_option.add_item("🇬🇧  English", 0)
		lang_option.add_item("🇷🇺  Русский", 1)
		
		if TranslationServer.get_locale().begins_with("ru"):
			lang_option.select(1)
		else:
			lang_option.select(0)
		
	# Обновляем локализацию
	_localize_ui_elements()
	
	# Fix CheckButton overlap
	if swap_button:
		# Use stable layout: Separation and text alignment
		swap_button.add_theme_constant_override("h_separation", 20)
		swap_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		swap_button.text = tr("Mirrored")

	
	# Apply Premium Stylings
	var panel = find_child("Panel")
	if panel is Panel:
		UIEffects.style_premium_panel(panel)
	
	var back_btn = find_child("BackButton")
	if back_btn is Button:
		UIEffects.setup_button(back_btn)
		if not back_btn.pressed.is_connected(_on_back_pressed):
			back_btn.pressed.connect(_on_back_pressed)
			
	UIEffects.fade_in(self)
	if panel: UIEffects.slide_up(panel)
	
	set_block_signals(old_block)


func _localize_ui_elements() -> void:
	# Заголовок
	var title = find_child("Title")
	if title: title.text = tr("SETTINGS")
	
	var music_lbl = find_child("MusicVolLabel")
	if music_lbl: music_lbl.text = tr("Music Volume")
	
	var sfx_lbl = find_child("SFXVolLabel")
	if sfx_lbl: sfx_lbl.text = tr("SFX Volume")
	
	var swap_lbl = find_child("SwapLabel")
	if swap_lbl: swap_lbl.text = tr("Swap Layout")
	
	if swap_button:
		swap_button.text = tr("Mirrored")
	
	var opac_lbl = find_child("OpacityLabel")
	if opac_lbl: opac_lbl.text = tr("Controls Opacity")
	
	var size_lbl = find_child("JoystickSizeLabel")
	if size_lbl: size_lbl.text = tr("Joystick Scale")
	
	var back_btn = find_child("BackButton")
	if back_btn: back_btn.text = tr("BACK")
	
	var lang_lbl = find_child("LangLabel")
	if lang_lbl: lang_lbl.text = tr("Language")
	
	# Названия вкладок
	var tabs = find_child("TabContainer")
	if tabs:
		tabs.set_tab_title(0, tr("Audio"))
		tabs.set_tab_title(1, tr("Controls"))
		tabs.set_tab_title(2, tr("Language"))
	
	# Update programmatically created button if it exists
	var customize_btn = find_child("CustomizeLayoutButton", true, false)
	if customize_btn:
		customize_btn.text = tr("CUSTOMIZE LAYOUT")


func _on_music_volume_changed(value: float) -> void:
	if not is_blocking_signals():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.set_music_volume(value)
		GameManager.audio_music_volume = value
		GameManager.save_game()

func _on_sfx_volume_changed(value: float) -> void:
	if not is_blocking_signals():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.set_sfx_volume(value)
		GameManager.audio_sfx_volume = value
		GameManager.save_game()

func _on_mobile_settings_changed(_val = null) -> void:
	if not is_blocking_signals():
		GameManager.update_mobile_settings(swap_button.button_pressed, opacity_slider.value, joystick_slider.value)

func _on_lang_selected(index: int) -> void:
	match index:
		0:
			GameManager.set_language("en")
		1:
			GameManager.set_language("ru")
	_localize_ui_elements()

func _on_customize_layout_pressed() -> void:
	# Create a full-screen overlay for customization
	var overlay = Panel.new()
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Stylize overlay (dark background but not affecting children)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	overlay.add_theme_stylebox_override("panel", style)
	
	# The customization logic node
	var custom_node = Control.new()
	custom_node.set_script(load("res://scenes/ui/controls_customizer.gd"))
	custom_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(custom_node)
	
	# Add the actual interactive elements
	var joy_mock = Control.new()
	joy_mock.name = "Joystick"
	joy_mock.custom_minimum_size = Vector2(200, 200)
	joy_mock.size = Vector2(200, 200)
	joy_mock.pivot_offset = Vector2(100, 100)
	joy_mock.set_script(load("res://scenes/ui/joystick.gd"))
	custom_node.add_child(joy_mock)
	
	var dash_mock = Button.new()
	dash_mock.name = "Dash"
	dash_mock.text = "DASH"
	dash_mock.custom_minimum_size = Vector2(120, 120)
	dash_mock.size = Vector2(120, 120)
	dash_mock.pivot_offset = Vector2(60, 60)
	
	# Dash Button Styling
	var dash_style = StyleBoxFlat.new()
	dash_style.bg_color = Color(1, 1, 1, 0.3)
	dash_style.corner_radius_top_left = 60
	dash_style.corner_radius_top_right = 60
	dash_style.corner_radius_bottom_left = 60
	dash_style.corner_radius_bottom_right = 60
	dash_mock.add_theme_stylebox_override("normal", dash_style)
	dash_mock.add_theme_stylebox_override("hover", dash_style)
	custom_node.add_child(dash_mock)
	
	# Header Label
	var header = Label.new()
	header.text = tr("DRAG BUTTONS TO MOVE THEM")
	header.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	header.position.y = 50
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 32)
	custom_node.add_child(header)
	
	# Footer Buttons
	var footer = HBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	footer.offset_bottom = -50
	footer.offset_top = -120
	footer.offset_left = -220
	footer.offset_right = 220
	footer.add_theme_constant_override("separation", 20)
	custom_node.add_child(footer)
	
	var save_btn = Button.new()
	save_btn.name = "SaveButton"
	save_btn.text = tr("SAVE")
	save_btn.custom_minimum_size = Vector2(200, 60)
	footer.add_child(save_btn)
	
	var reset_btn = Button.new()
	reset_btn.name = "ResetButton"
	reset_btn.text = tr("RESET")
	reset_btn.custom_minimum_size = Vector2(200, 60)
	footer.add_child(reset_btn)
	
	# Connect closing signals safely
	save_btn.pressed.connect(func(): if is_instance_valid(overlay): overlay.queue_free())
	reset_btn.pressed.connect(func(): if is_instance_valid(overlay): overlay.queue_free())
	
	# Ensure overlay is visible and on top
	if get_parent():
		get_parent().add_child(overlay)
	else:
		get_tree().root.add_child(overlay)

func _on_back_pressed() -> void:
	back_pressed.emit()
	queue_free()
