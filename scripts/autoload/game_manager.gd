extends Node
## Глобальный менеджер игры - управляет сложностью и состоянием

signal difficulty_changed(level: int)
signal game_over
signal currency_changed(amount: int)
signal boss_spawned(boss_name: String, max_hp: float)
signal boss_health_changed(current_hp: float, max_hp: float)
signal boss_died
signal mobile_settings_changed
 
## Размер игрового мира (для границ и спавна)
const WORLD_SIZE: float = 5000.0

## Текущий уровень сложности
var difficulty_level: int = 1

## Множитель здоровья врагов
var enemy_hp_multiplier: float = 1.0
## Множитель урона врагов
var enemy_damage_multiplier: float = 1.0
## Множитель скорости врагов
var enemy_speed_multiplier: float = 1.0

## Прирост характеристик за уровень сложности
const HP_INCREASE_PER_LEVEL: float = 0.05
const DAMAGE_INCREASE_PER_LEVEL: float = 0.04
const SPEED_INCREASE_PER_LEVEL: float = 0.015

## Базовый интервал спавна
const BASE_SPAWN_INTERVAL: float = 2.8

## Ограничения прокачки
const MAX_AURA_RADIUS: float = 350.0
const MAX_AURA_DAMAGE: float = 300.0
const MIN_AURA_INTERVAL: float = 0.12

## Статистика текущего забега
var kills: int = 0

## Currency and Progression
var soul_shards: int = 0
var talents: Dictionary = {}
var current_language: String = "en"

# Records
var max_kills: int = 0
var max_time: float = 0.0

# Mobile Settings
var mobile_swap_controls: bool = false
var mobile_controls_opacity: float = 0.8
var mobile_joystick_scale: float = 1.0
var mobile_joystick_pos: Vector2 = Vector2(-1, -1) # -1 means use default
var mobile_dash_pos: Vector2 = Vector2(-1, -1)
var mobile_pause_pos: Vector2 = Vector2(-1, -1)

# Audio Settings
var audio_music_volume: float = 0.8
var audio_sfx_volume: float = 1.0

const SAVE_PATH: String = "user://savegame.save"

var player: Node
var aura: Node

func _ready() -> void:
	_setup_translations()
	load_game()

func _setup_translations() -> void:
	# Russian Translation
	var ru = Translation.new()
	ru.locale = "ru"
	var ru_strings = {
		# General
		"SETTINGS": "НАСТРОЙКИ",
		"BACK": "НАЗАД",
		"OPTIONS": "НАСТРОЙКИ",
		"GRIM DEPTHS": "МРАЧНЫЕ ГЛУБИНЫ",
		
		# Main Menu
		"START EXPEDITION": "НАЧАТЬ ПОХОД",
		"CHARACTER TALENTS": "ТАЛАНТЫ",
		"EXIT TO DESKTOP": "ВЫХОД",
		"Soul Shards:": "Осколки душ:",
		"BEST RECORD:": "ЛУЧШИЙ РЕЗУЛЬТАТ:",
		"Kills:": "Убийства:",
		"Time:": "Время:",
		
		# Settings
		"Audio": "Аудио",
		"Controls": "Управление",
		"Language": "Язык",
		"Master Volume": "Общая громкость",
		"Music Volume": "Громкость музыки",
		"SFX Volume": "Громкость звуков",
		"Swap Layout": "Сменить стороны",
		"Mirrored": "Зеркально",
		"Right-handed": "Для правшей",
		"Controls Opacity": "Прозрачность",
		"Joystick Scale": "Размер джойстика",
		"Window Mode": "Режим экрана",
		"Resolution": "Разрешение",
		"Windowed": "В окне",
		"Fullscreen": "На весь экран",
		
		# In-Game
		"PAUSE": "ПАУЗА",
		"PAUSED": "ПАУЗА",
		"RESUME": "ПРОДОЛЖИТЬ",
		"RESTART": "ЗАНОВО",
		"MAIN MENU": "В МЕНЮ",
		"RETURN TO HUB": "В ХАБ",
		"GAME OVER": "ИГРА ОКОНЧЕНА",
		"THE DEPTHS CLAIMED YOU": "БЕЗДНА ПОГЛОТИЛА ВАС",
		"VICTORY": "ПОБЕДА",
		"YOU SURVIVED!": "ВЫ ВЫЖИЛИ!",
		"RETRY EXPEDITION": "ПОВТОРИТЬ ПОХОД",
		"RESUME EXPEDITION": "ПРОДОЛЖИТЬ ПОХОД",
		
		"Level %d": "Уровень %d",
		"LEVEL UP!": "НОВЫЙ УРОВЕНЬ!",
		"Choose your reward:": "Выберите награду:",
		
		# Results
		"RESULTS:": "РЕЗУЛЬТАТЫ:",
		"Survival Time:": "Время выживания:",
		"Player Level:": "Уровень игрока:",
		"Total Kills:": "Всего убийств:",
		
		# Upgrades
		"Speed Boost": "Ускорение",
		"Aura Power": "Сила ауры",
		"Aura Expansion": "Радиус ауры",
		"Aura Haste": "Скорость ауры",
		"Max Health": "Здоровье",
		"Magnet": "Магнит",
		
		"Increases movement speed": "Увеличивает скорость движения",
		"Increases aura damage": "Увеличивает урон ауры",
		"Increases aura radius": "Увеличивает радиус ауры",
		"Increases aura attack speed": "Повышает скорость атаки ауры",
		"Increases max HP": "Увеличивает максимальное здоровье",
		"Increases experience collection radius": "Увеличивает радиус сбора опыта",
		"CUSTOMIZE LAYOUT": "УПРАВЛЕНИЕ КНОПКАМИ",
		"SAVE": "СОХРАНИТЬ",
		"RESET": "СБРОС",
		"DRAG BUTTONS": "ПЕРЕТАЩИТЕ КНОПКИ",
		"DRAG BUTTONS TO MOVE THEM": "ПЕРЕТАЩИТЕ КНОПКИ ДЛЯ ИЗМЕНЕНИЯ",
		"MIRRORED": "ЗЕРКАЛЬНО",
		"LEVEL UP": "НОВЫЙ УРОВЕНЬ"
	}
	for key in ru_strings:
		ru.add_message(key, ru_strings[key])
	TranslationServer.add_translation(ru)
	
	# English Translation
	var en = Translation.new()
	en.locale = "en"
	var en_strings = {
		"SETTINGS": "SETTINGS",
		"BACK": "BACK",
		"OPTIONS": "OPTIONS",
		"GRIM DEPTHS": "GRIM DEPTHS",
		"START EXPEDITION": "START EXPEDITION",
		"CHARACTER TALENTS": "CHARACTER TALENTS",
		"EXIT TO DESKTOP": "EXIT TO DESKTOP",
		"Soul Shards:": "Soul Shards:",
		"BEST RECORD:": "BEST RECORD:",
		"Kills:": "Kills:",
		"Time:": "Time:",
		"Audio": "Audio",
		"Controls": "Controls",
		"Language": "Language",
		"Master Volume": "Master Volume",
		"Music Volume": "Music Volume",
		"SFX Volume": "SFX Volume",
		"Swap Layout": "Swap Layout",
		"Mirrored": "Mirrored",
		"Right-handed": "Right-handed",
		"Controls Opacity": "Controls Opacity",
		"Joystick Scale": "Joystick Scale",
		"Window Mode": "Window Mode",
		"Resolution": "Resolution",
		"Windowed": "Windowed",
		"Fullscreen": "Fullscreen",
		"PAUSE": "PAUSE",
		"PAUSED": "PAUSED",
		"RESUME": "RESUME",
		"RESTART": "RESTART",
		"MAIN MENU": "MAIN MENU",
		"RETURN TO HUB": "RETURN TO HUB",
		"GAME OVER": "GAME OVER",
		"THE DEPTHS CLAIMED YOU": "THE DEPTHS CLAIMED YOU",
		"VICTORY": "VICTORY",
		"YOU SURVIVED!": "YOU SURVIVED!",
		"RETRY EXPEDITION": "RETRY EXPEDITION",
		"RESUME EXPEDITION": "RESUME EXPEDITION",
		"Level %d": "Level %d",
		"LEVEL UP!": "LEVEL UP!",
		"Choose your reward:": "Choose your reward:",
		"RESULTS:": "RESULTS:",
		"Survival Time:": "Survival Time:",
		"Player Level:": "Player Level:",
		"Total Kills:": "Total Kills:",
		"Speed Boost": "Speed Boost",
		"Aura Power": "Aura Power",
		"Aura Expansion": "Aura Expansion",
		"Aura Haste": "Aura Haste",
		"Max Health": "Max Health",
		"Magnet": "Magnet",
		"Increases movement speed": "Increases movement speed",
		"Increases aura damage": "Increases aura damage",
		"Increases aura radius": "Increases aura radius",
		"Increases aura attack speed": "Increases aura attack speed",
		"Increases max HP": "Increases max HP",
		"Increases experience collection radius": "Increases experience collection radius",
		"CUSTOMIZE LAYOUT": "CUSTOMIZE LAYOUT",
		"SAVE": "SAVE",
		"RESET": "RESET",
		"DRAG BUTTONS": "DRAG BUTTONS",
		"DRAG BUTTONS TO MOVE THEM": "DRAG BUTTONS TO MOVE THEM",
		"MIRRORED": "MIRRORED",
		"LEVEL UP": "LEVEL UP"
	}
	for key in en_strings:
		en.add_message(key, en_strings[key])
	TranslationServer.add_translation(en)
	
	# Set default to English
	TranslationServer.set_locale("en")

func reset() -> void:
	difficulty_level = 1
	enemy_hp_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	enemy_speed_multiplier = 1.0
	kills = 0

func increase_difficulty() -> void:
	difficulty_level += 1
	# Нелинейный рост, откалиброванный для идеального баланса
	enemy_hp_multiplier = 1.0 + (difficulty_level - 1) * HP_INCREASE_PER_LEVEL
	# Урон растет чуть агрессивнее после 14 уровня (6.5 минут)
	var damage_accel = 1.0 if difficulty_level < 14 else 1.25
	enemy_damage_multiplier = 1.0 + (difficulty_level - 1) * DAMAGE_INCREASE_PER_LEVEL * damage_accel
	# Скорость растет очень плавно
	enemy_speed_multiplier = 1.0 + (difficulty_level - 1) * SPEED_INCREASE_PER_LEVEL
	difficulty_changed.emit(difficulty_level)

func register_player(new_player: Node):
	player = new_player
	apply_talents_to_player()

func register_aura(new_aura: Node):
	aura = new_aura
	if aura:
		aura.aura_radius = 60.0 # Увеличен радиус на старте
		aura.damage = 26.0      # Теперь убиваем скелетов за 2 удара вместо 3
		aura.attack_interval = 1.0 # Бьем чуть чаще
	apply_talents_to_aura()

func get_random_upgrades(count: int) -> Array:
	var possible_upgrades = [
		{
			"name": "Speed Boost",
			"description": "Increases movement speed",
			"property": "player_speed",
			"value": 15.0
		},
		{
			"name": "Aura Power",
			"description": "Increases aura damage",
			"property": "aura_damage",
			"value": 5.0
		},
		{
			"name": "Aura Expansion",
			"description": "Increases aura radius",
			"property": "aura_radius",
			"value": 20.0
		},
		{
			"name": "Aura Haste",
			"description": "Increases aura attack speed",
			"property": "aura_interval",
			"value": -0.15
		},
		{
			"name": "Max Health",
			"description": "Increases max HP",
			"property": "max_hp",
			"value": 20.0
		},
		{
			"name": "Magnet",
			"description": "Increases experience collection radius",
			"property": "collection_radius",
			"value": 30.0
		}
	]
	
	var chosen_upgrades = []
	var available = possible_upgrades.duplicate()
	
	for i in range(min(count, available.size())):
		var random_index = randi() % available.size()
		chosen_upgrades.append(available[random_index])
		available.remove_at(random_index)
		
	return chosen_upgrades

func apply_upgrade(upgrade: Dictionary):
	match upgrade["property"]:
		"aura_damage":
			if aura:
				aura.damage = min(aura.damage + upgrade["value"], MAX_AURA_DAMAGE)
		"aura_radius":
			if aura:
				aura.aura_radius = min(aura.aura_radius + upgrade["value"], MAX_AURA_RADIUS)
		"aura_interval":
			if aura:
				aura.attack_interval = max(aura.attack_interval + upgrade["value"], MIN_AURA_INTERVAL)
		"player_speed":
			if player:
				player.speed += upgrade["value"]
		"max_hp":
			if player:
				player.max_hp += upgrade["value"]
				player.hp += upgrade["value"]
				player.health_changed.emit(player.hp, player.max_hp)
		"collection_radius":
			if player:
				player.collection_radius += upgrade["value"]

func set_language(locale: String) -> void:
	current_language = locale
	TranslationServer.set_locale(locale)
	save_game()

func update_mobile_settings(swap: bool, opacity: float, scale: float, joy_pos: Vector2 = Vector2(-1,-1), dash_pos: Vector2 = Vector2(-1,-1)) -> void:
	mobile_swap_controls = swap
	mobile_controls_opacity = opacity
	mobile_joystick_scale = scale
	if joy_pos != Vector2(-1, -1):
		mobile_joystick_pos = joy_pos
	if dash_pos != Vector2(-1, -1):
		mobile_dash_pos = dash_pos
	mobile_settings_changed.emit()
	save_game()

func trigger_game_over() -> void:
	game_over.emit()

func update_records(new_time: float, new_kills: int) -> bool:
	var improved = false
	if new_kills > max_kills:
		max_kills = new_kills
		improved = true
	if new_time > max_time:
		max_time = new_time
		improved = true
	
	if improved:
		save_game()
	return improved

### Persistence & Currency ###

func add_shards(amount: int) -> void:
	soul_shards += amount
	save_game()
	currency_changed.emit(soul_shards)

func spend_shards(amount: int) -> bool:
	if soul_shards >= amount:
		soul_shards -= amount
		save_game()
		currency_changed.emit(soul_shards)
		return true
	return false

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"soul_shards": soul_shards,
			"talents": talents,
			"language": current_language,
			"mobile_swap": mobile_swap_controls,
			"mobile_opacity": mobile_controls_opacity,
			"mobile_scale": mobile_joystick_scale,
			"mobile_joy_pos_x": mobile_joystick_pos.x,
			"mobile_joy_pos_y": mobile_joystick_pos.y,
			"mobile_dash_pos_x": mobile_dash_pos.x,
			"mobile_dash_pos_y": mobile_dash_pos.y,
			"audio_music_volume": audio_music_volume,
			"audio_sfx_volume": audio_sfx_volume,
			"max_kills": max_kills,
			"max_time": max_time
		}
		file.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		if data:
			soul_shards = int(data.get("soul_shards", 0))
			talents = data.get("talents", {})
			current_language = data.get("language", "en")
			mobile_swap_controls = data.get("mobile_swap", false)
			mobile_controls_opacity = data.get("mobile_opacity", 0.8)
			mobile_joystick_scale = data.get("mobile_scale", 1.0)
			mobile_joystick_pos = Vector2(data.get("mobile_joy_pos_x", -1), data.get("mobile_joy_pos_y", -1))
			mobile_dash_pos = Vector2(data.get("mobile_dash_pos_x", -1), data.get("mobile_dash_pos_y", -1))
			audio_music_volume = data.get("audio_music_volume", 0.8)
			audio_sfx_volume = data.get("audio_sfx_volume", 1.0)
			max_kills = int(data.get("max_kills", 0))
			max_time = float(data.get("max_time", 0.0))
			TranslationServer.set_locale(current_language)

func unlock_talent(talent_id: String, cost: int) -> bool:
	if talents.has(talent_id):
		return true # Already unlocked
		
	if spend_shards(cost):
		talents[talent_id] = true
		save_game()
		# Re-apply stats if in-game
		apply_talents_to_player()
		apply_talents_to_aura()
		return true
	return false

func apply_talents_to_player() -> void:
	if not player: return
	
	# Example talent application logic
	if talents.get("hp_boost_1", false):
		player.max_hp += 20
		player.hp += 20
	if talents.get("speed_boost_1", false):
		player.speed += 20

func apply_talents_to_aura() -> void:
	if not aura: return
	
	if talents.get("aura_dmg_1", false):
		aura.damage += 5
	if talents.get("aura_range_1", false):
		aura.aura_radius += 15
