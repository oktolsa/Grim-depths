extends Area2D
class_name ExperienceGem

## Количество опыта, которое даёт гем
@export var experience_value: int = 10
## Базовая скорость полёта к игроку
@export var base_fly_speed: float = 80.0
## Максимальная скорость полёта
@export var max_fly_speed: float = 450.0
## Целевой масштаб гема при появлении
@export var target_scale: Vector2 = Vector2(1.8, 1.8)

var _is_collecting: bool = false
var _player: Node2D
var _current_fly_speed: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Устанавливаем иконку (один раз за жизнь объекта)
	if sprite:
		sprite.texture = load("res://Assets/orb.png")
		sprite.modulate = Color.WHITE
	
	body_entered.connect(_on_body_entered)
	on_reuse()

## Вызывается при извлечении из пула объектов
func on_reuse() -> void:
	_is_collecting = false
	_current_fly_speed = base_fly_speed
	scale = Vector2.ZERO
	
	# Сбрасываем флаги Area2D
	monitoring = true
	monitorable = true
	
	# Плавное появление (отложено до входа в дерево)
	if is_inside_tree():
		_play_spawn_animation()
	elif not tree_entered.is_connected(_play_spawn_animation):
		tree_entered.connect(_play_spawn_animation, CONNECT_ONE_SHOT)
	
	# Останавливаем физику до того как начнем сбор
	set_physics_process(false)
	set_process(true)

func _play_spawn_animation() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.3)

func _physics_process(delta: float) -> void:
	if _is_collecting:
		_fly_to_player(delta)

func _start_collecting() -> void:
	if _is_collecting: return
	
	_player = GameManager.player
	if not _player: return
	
	_is_collecting = true
	set_physics_process(true)
	# Отключаем мониторинг, теперь летим по скрипту
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func _fly_to_player(delta: float) -> void:
	if not is_instance_valid(_player):
		ObjectPool.return_instance(self)
		return
	
	# Ускоряемся со временем для эффекта притяжения
	_current_fly_speed = lerp(_current_fly_speed, max_fly_speed, delta * 4.0)
	
	var direction := global_position.direction_to(_player.global_position)
	global_position += direction * _current_fly_speed * delta
	
	# Плавное уменьшение размера при приближении к самому центру игрока
	var distance := global_position.distance_to(_player.global_position)
	if distance < 30.0:
		scale = target_scale * (distance / 30.0)
	
	# Проверяем достижение игрока
	if distance < 10.0:
		_collect()

func _collect() -> void:
	if is_instance_valid(_player) and _player.has_method("add_experience"):
		_player.add_experience(experience_value)
	
	# Возвращаем в пул вместо уничтожения
	ObjectPool.return_instance(self)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _is_collecting:
		_start_collecting()
