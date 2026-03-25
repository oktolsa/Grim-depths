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

func _on_back_pressed() -> void:
	back_pressed.emit()
	queue_free()
