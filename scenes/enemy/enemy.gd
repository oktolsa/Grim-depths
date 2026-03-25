extends CharacterBody2D
class_name Enemy

## Сигнал смерти врага, передаёт позицию для спавна лута
signal died(death_position: Vector2)

## Сцена гема опыта для спавна при смерти
@export var experience_gem_scene: PackedScene
## Количество опыта за убийство
@export var experience_value: int = 10
## Максимальное здоровье врага (базовое)
@export var base_max_hp: float = 50.0
## Скорость движения врага (базовая)
@export var base_speed: float = 60.0
## Урон при контакте (базовый)
@export var base_contact_damage: float = 10.0
## Длительность эффекта урона (мигание красным)
@export var damage_flash_duration: float = 0.1

var hp: float
var max_hp: float
var speed: float
var contact_damage: float
var _player: Node2D

@onready var damage_flash_timer: Timer = $DamageFlashTimer

## Флаг хибернации для оптимизации
var _is_hibernating: bool = false
const HIBERNATION_DISTANCE: float = 1200.0

func _ready() -> void:
	_setup_damage_flash_timer()
	on_reuse()

## Вызывается при извлечении из пула объектов
func on_reuse() -> void:
	_apply_difficulty_scaling()
	hp = max_hp
	_is_hibernating = false
	set_process(true)
	set_physics_process(true)
	modulate = Color.WHITE
	if damage_flash_timer:
		damage_flash_timer.stop()

func _apply_difficulty_scaling() -> void:
	max_hp = base_max_hp * GameManager.enemy_hp_multiplier
	speed = base_speed * GameManager.enemy_speed_multiplier
	contact_damage = base_contact_damage * GameManager.enemy_damage_multiplier

func _setup_damage_flash_timer() -> void:
	damage_flash_timer.one_shot = true
	damage_flash_timer.wait_time = damage_flash_duration
	damage_flash_timer.timeout.connect(_on_damage_flash_timer_timeout)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = GameManager.player
		if not _player:
			return
	
	# Логика хибернации (проверка раз в несколько кадров была бы ещё лучше, но и так ок)
	var dist_sq := global_position.distance_squared_to(_player.global_position)
	if dist_sq > HIBERNATION_DISTANCE * HIBERNATION_DISTANCE:
		if not _is_hibernating:
			_is_hibernating = true
		return
	
	_is_hibernating = false
	_move_towards_player(delta)

func _move_towards_player(delta: float) -> void:
	var direction := global_position.direction_to(_player.global_position)
	
	# Простейшее разделение (separation) для предотвращения идеального наложения врагов
	# Ищем ближайших врагов в небольшой области (очень быстро через группы)
	var separation := Vector2.ZERO
	# Оптимизация: проверяем только некоторых врагов или используем дистанцию
	# Для 100+ врагов лучше просто добавить небольшой рандом или проверять раз в N кадров
	# Но мы сделаем проще и эффективнее:
	var push_force = 15.0
	separation += Vector2(randf_range(-push_force, push_force), randf_range(-push_force, push_force))
	
	velocity = (direction * speed) + separation
	# Перемещаем объект
	global_position += velocity * delta
	
	# Поворот спрайта (если есть Sprite2D)
	var sprite = get_node_or_null("Sprite2D")
	if sprite and velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func take_damage(amount: float) -> void:
	hp -= amount
	_show_damage_flash()
	
	if hp <= 0:
		_die()

func _show_damage_flash() -> void:
	modulate = Color.RED
	damage_flash_timer.start()

func _on_damage_flash_timer_timeout() -> void:
	modulate = Color.WHITE

func _die() -> void:
	GameManager.kills += 1
	var death_pos := global_position
	died.emit(death_pos)
	_spawn_experience_gem(death_pos)
	# Вместо queue_free() возвращаем в пул
	if has_meta("scene_path"):
		ObjectPool.return_instance(self)
	else:
		queue_free()

func _spawn_experience_gem(pos: Vector2) -> void:
	if not experience_gem_scene:
		return
	
	# Используем пул объектов для гемов опыта
	var gem := ObjectPool.get_instance(experience_gem_scene) as ExperienceGem
	if gem:
		gem.experience_value = experience_value
		gem.global_position = pos
		
		# Пытаемся добавить в контейнер сущностей
		var containers = get_tree().get_nodes_in_group("entity_container")
		if containers.size() > 0:
			containers[0].add_child(gem)
		else:
			# Фолбек на текущего родителя
			var p = get_parent()
			if p:
				p.add_child(gem)
