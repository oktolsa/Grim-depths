extends Control
class_name SettingsMenu

signal back_pressed

@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var mode_option: OptionButton = %ModeOptionButton
@onready var resolution_option: OptionButton = %ResOptionButton
@onready var lang_option: OptionButton = %LangOptionButton

var master_bus_idx: int
var sfx_bus_idx: int

func _ready() -> void:
	master_bus_idx = AudioServer.get_bus_index("Master")
	# If SFX bus doesn't exist, we create it
	sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx == -1:
		AudioServer.add_bus()
		var new_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(new_idx, "SFX")
		sfx_bus_idx = new_idx
	_setup_ui()
	
	# Connect signals
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if mode_option:
		mode_option.item_selected.connect(_on_mode_selected)
	if resolution_option:
		resolution_option.item_selected.connect(_on_resolution_selected)
	if lang_option:
		lang_option.item_selected.connect(_on_lang_selected)

func _setup_ui() -> void:
	# Volumes
	if master_slider and master_bus_idx != -1:
		master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_idx))
	if sfx_slider and sfx_bus_idx != -1:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))

	# Window Mode
	if mode_option:
		mode_option.clear()
		mode_option.add_item(tr("Windowed"), 0)
		mode_option.add_item(tr("Fullscreen"), 1)
		
		var current_mode = DisplayServer.window_get_mode()
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			mode_option.select(1)
		else:
			mode_option.select(0)

	# Resolution
	if resolution_option:
		resolution_option.clear()
		var resolutions = [
			Vector2i(1280, 720),
			Vector2i(1366, 768),
			Vector2i(1600, 900),
			Vector2i(1920, 1080),
			Vector2i(2560, 1440)
		]
		
		var current_size = DisplayServer.window_get_size()
		var selected_idx = 3 # Default 1920x1080 usually
		
		for i in range(resolutions.size()):
			var res = resolutions[i]
			resolution_option.add_item("%dx%d" % [res.x, res.y], i)
			resolution_option.set_item_metadata(i, res)
			if res == current_size:
				selected_idx = i
				
		resolution_option.select(selected_idx)

	# Language
	if lang_option:
		lang_option.clear()
		
		# Load textures for icons and resize them safely
		var en_tex = load("res://Assets/Flag/United Kingdom Flag Pixel Art.jpg")
		var en_flag = en_tex
		if en_tex:
			var img = en_tex.get_image()
			if img:
				img.resize(32, 24)
				en_flag = ImageTexture.create_from_image(img)
		
		var ru_tex = load("res://Assets/Flag/Russia Flag Pixel Art.jpg")
		var ru_flag = ru_tex
		if ru_tex:
			var img = ru_tex.get_image()
			if img:
				img.resize(32, 24)
				ru_flag = ImageTexture.create_from_image(img)

		if en_flag: lang_option.add_icon_item(en_flag, "English", 0)
		else: lang_option.add_item("English", 0)
		
		if ru_flag: lang_option.add_icon_item(ru_flag, "Русский", 1)
		else: lang_option.add_item("Русский", 1)
		
		# Set selected item based on current locale
		if TranslationServer.get_locale().begins_with("ru"):
			lang_option.select(1)
		else:
			lang_option.select(0)

func _on_master_volume_changed(value: float) -> void:
	if master_bus_idx != -1:
		AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(value))

func _on_sfx_volume_changed(value: float) -> void:
	if sfx_bus_idx != -1:
		AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value))

func _on_mode_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_resolution_selected(index: int) -> void:
	var res = resolution_option.get_item_metadata(index)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED) # Ensure we're windowed to resize
	DisplayServer.window_set_size(res)
	
	# Center window
	var screen_size = DisplayServer.screen_get_size()
	var new_pos = screen_size / 2 - res / 2
	DisplayServer.window_set_position(new_pos)

func _on_lang_selected(index: int) -> void:
	match index:
		0:
			TranslationServer.set_locale("en")
		1:
			TranslationServer.set_locale("ru")
	_setup_ui()

func _on_back_pressed() -> void:
	back_pressed.emit()
	queue_free()
