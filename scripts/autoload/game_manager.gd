extends Node
## Глобальный менеджер игры - управляет сложностью и состоянием

signal difficulty_changed(level: int)
signal game_over
signal currency_changed(amount: int)
signal boss_spawned(boss_name: String, max_hp: float)
signal boss_health_changed(current_hp: float, max_hp: float)
signal boss_died
 
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
const HP_INCREASE_PER_LEVEL: float = 0.08
const DAMAGE_INCREASE_PER_LEVEL: float = 0.05
const SPEED_INCREASE_PER_LEVEL: float = 0.02

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
const SAVE_PATH: String = "user://savegame.save"

var player: Node
var aura: Node

func _ready() -> void:
	_setup_translations()
	load_game()

func _setup_translations() -> void:
	var ru = Translation.new()
	ru.locale = "ru"
	var strings = {
		"SETTINGS": "НАСТРОЙКИ",
		"Master Volume": "Общая громкость",
		"SFX Volume": "Громкость эффектов",
		"Window Mode": "Режим экрана",
		"Resolution": "Разрешение",
		"Language": "Язык",
		"Windowed": "В окне",
		"Fullscreen": "На весь экран",
		"BACK": "НАЗАД",
		"Audio": "Аудио",
		"Display": "Экран",
		
		"START EXPEDITION": "НАЧАТЬ ЭКСПЕДИЦИЮ",
		"CHARACTER TALENTS": "ТАЛАНТЫ ПЕРСОНАЖА",
		"OPTIONS": "НАСТРОЙКИ",
		"EXIT TO DESKTOP": "ВЫХОД",
		"GRIM DEPTHS": "МРАЧНЫЕ ГЛУБИНЫ",
		"Soul Shards:": "Осколки душ:",
		
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
		
		"Upgrade 1": "Улучшение 1",
		"Upgrade 2": "Улучшение 2",
		"Upgrade 3": "Улучшение 3"
	}
	for key in strings:
		ru.add_message(key, strings[key])
	TranslationServer.add_translation(ru)

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
	# Урон растет чуть агрессивнее после 5 уровня
	var damage_accel = 1.0 if difficulty_level < 5 else 1.2
	enemy_damage_multiplier = 1.0 + (difficulty_level - 1) * DAMAGE_INCREASE_PER_LEVEL * damage_accel
	# Скорость растет плавно, достигая значимых величин к 10 минуте
	enemy_speed_multiplier = 1.0 + (difficulty_level - 1) * SPEED_INCREASE_PER_LEVEL * 0.8
	difficulty_changed.emit(difficulty_level)

func register_player(new_player: Node):
	player = new_player
	apply_talents_to_player()

func register_aura(new_aura: Node):
	aura = new_aura
	if aura:
		aura.aura_radius = 45.0 # Маленький радиус на старте
		aura.damage = 18.0      # Быстрее убиваем первых скелетов
		aura.attack_interval = 1.15
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

func trigger_game_over() -> void:
	game_over.emit()

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
			"talents": talents
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
