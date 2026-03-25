extends Node2D
class_name EnemySpawner

## Базовая сцена врага (скелет)
@export var enemy_scene: PackedScene
## Список дополнительных типов врагов для спавна
@export var extra_enemy_scenes: Array[PackedScene] = []
## Интервал спавна в секундах (не используется, берем из GameManager)
@export var spawn_interval: float = 2.0
## Минимальный радиус спавна от игрока
@export var min_spawn_radius: float = 400.0
## Максимальный радиус спавна от игрока
@export var max_spawn_radius: float = 600.0
## Сцена босса для регулярного спавна
@export var boss_scene: PackedScene

var _player: Node2D

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	_setup_spawn_timer()
	GameManager.difficulty_changed.connect(_on_difficulty_changed)
	
	# Предварительное наполнение пула (безопасно)
	if enemy_scene:
		ObjectPool.pre_populate(enemy_scene, 30)
	for scene in extra_enemy_scenes:
		ObjectPool.pre_populate(scene, 15)
		
	# Предварительное наполнение для гемов опыта и стрел (частые объекты)
	var gem_scene = load("res://scenes/experience_gem/experience_gem.tscn")
	if gem_scene:
		ObjectPool.pre_populate(gem_scene, 60)
		
	var proj_scene = load("res://scenes/enemy/goblin_archer/goblin_projectile.tscn")
	if proj_scene:
		ObjectPool.pre_populate(proj_scene, 25)

func _setup_spawn_timer() -> void:
	# Начальное значение интервала
	spawn_timer.wait_time = GameManager.BASE_SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_difficulty_changed(level: int) -> void:
	# С каждыми 30 секундами спавн ускоряется на 5% (было 10%)
	var new_interval = GameManager.BASE_SPAWN_INTERVAL * pow(0.95, level - 1)
	spawn_timer.wait_time = max(0.4, new_interval) # Увеличен минимальный предел
	
	# Босс спавнится каждые 3 минуты = 6 уровней
	# Первый босс появится на уровне 7 (ровно через 3 минуты)
	if level > 1 and (level - 1) % 6 == 0 and boss_scene:
		_spawn_boss()

func _spawn_boss() -> void:
	_player = GameManager.player
	if not _player or not is_instance_valid(_player):
		return
		
	var spawn_position := _get_random_spawn_position()
	var boss := boss_scene.instantiate()
	boss.global_position = spawn_position
	
	var entities := _get_entities_container()
	if entities and is_instance_valid(entities):
		entities.add_child(boss)
	else:
		get_tree().current_scene.add_child(boss)
	
	print("BOSS SPAWNED at ", spawn_position)

func _on_spawn_timer_timeout() -> void:
	_player = GameManager.player
	if _player and is_instance_valid(_player):
		# Агрессивный рост количества врагов
		var spawn_count = 1
		if GameManager.difficulty_level >= 5: # 2 мин
			spawn_count = 2
		if GameManager.difficulty_level >= 9: # 4 мин
			spawn_count = 3
		if GameManager.difficulty_level >= 13: # 6 мин
			spawn_count = 4
		if GameManager.difficulty_level >= 19: # 9 мин
			spawn_count = 5 # Слегка уменьшим максимум
		
		for i in range(spawn_count):
			_spawn_enemy()

func _spawn_enemy() -> void:
	var selected_scene = _select_enemy_scene()
	
	if not selected_scene:
		return
	
	if not _player or not is_instance_valid(_player):
		return
	
	var spawn_position := _get_random_spawn_position()
	if not _is_valid_spawn_position(spawn_position):
		return # Try next time
		
	var enemy := ObjectPool.get_instance(selected_scene)
	enemy.global_position = spawn_position
	
	# Убедимся, что враг не имеет родителя перед добавлением
	if enemy.get_parent():
		enemy.get_parent().remove_child(enemy)
	
	# Добавляем в контейнер Entities, если он существует
	var entities := _get_entities_container()
	if entities and is_instance_valid(entities):
		entities.add_child(enemy)
	else:
		# Добавляем в основную сцену напрямую
		get_tree().current_scene.add_child(enemy)

func _select_enemy_scene() -> PackedScene:
	var main = get_tree().current_scene
	var current_time = 0.0
	if main and "game_time" in main:
		current_time = main.game_time
	
	# Гоблин появляется через 30 секунд
	if current_time >= 30.0:
		for scene in extra_enemy_scenes:
			if "goblin_archer" in scene.resource_path.to_lower():
				# Даём шанс 25% на замену скелета гоблином
				if randf() < 0.25:
					return scene
	
	return enemy_scene

func _get_entities_container() -> Node2D:
	var containers = get_tree().get_nodes_in_group("entity_container")
	if containers.size() > 0:
		return containers[0] as Node2D
		
	var main := get_tree().current_scene
	if main.has_method("get_entities_container"):
		return main.get_entities_container()
	var entities := main.get_node_or_null("Entities")
	return entities as Node2D

func _get_random_spawn_position() -> Vector2:
	var angle := randf() * TAU
	var radius := randf_range(min_spawn_radius, max_spawn_radius)
	var offset := Vector2(cos(angle), sin(angle)) * radius
	var spawn_pos = _player.global_position + offset
	
	# Ограничиваем позицию спавна границами мира
	var half_size = GameManager.WORLD_SIZE / 2.0
	# С небольшим отступом от стен (например 50 пикселей)
	var margin = 50.0
	spawn_pos.x = clamp(spawn_pos.x, -half_size + margin, half_size - margin)
	spawn_pos.y = clamp(spawn_pos.y, -half_size + margin, half_size - margin)
	
	return spawn_pos

func _is_valid_spawn_position(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1 # World layer
	var result = space_state.intersect_point(query)
	return result.size() == 0
