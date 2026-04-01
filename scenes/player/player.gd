extends CharacterBody2D
class_name Player

signal died
signal health_changed(current_hp: float, max_hp: float)
signal experience_changed(current_exp: int, target_exp: int)
signal level_up(new_level: int)

## Скорость движения игрока
@export var speed: float = 160.0
@export var dash_speed: float = 300.0
@export var dash_duration: float = 0.2
## Максимальное здоровье
@export var max_hp: float = 100.0
## Время неуязвимости после получения урона
@export var invincibility_duration: float = 0.2
## Начальное количество опыта для первого уровня
@export var base_target_exp: int = 100
## Множитель увеличения требуемого опыта за уровень (1.2 = +20%)
@export var exp_multiplier: float = 1.2
## КД дэша
@export var dash_cooldown: float = 1.0
## Радиус сбора опыта
@export var collection_radius: float = 16.0:
	set(val):
		collection_radius = val
		if collection_shape and collection_shape.shape:
			collection_shape.shape.radius = collection_radius

var hp: float
var _is_invincible: bool = false
var _is_dashing: bool = false
var _dash_on_cooldown: bool = false

## Система уровней
var level: int = 1
var current_exp: int = 0
var target_exp: int = 100

@onready var invincibility_timer: Timer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
var dash_timer: Timer
var dash_cooldown_timer: Timer

# Новая зона сбора опыта
var experience_collector: Area2D
var collection_shape: CollisionShape2D

var _shake_strength: float = 0.0
var _shake_tween: Tween
var _last_position: Vector2


func _ready() -> void:
	hp = max_hp
	target_exp = base_target_exp
	_setup_invincibility_timer()
	_setup_dash_timer()
	_setup_dash_cooldown_timer()
	_setup_experience_collector()
	health_changed.emit(hp, max_hp)
	experience_changed.emit(current_exp, target_exp)
	GameManager.register_player(self)
	_last_position = global_position


func _setup_experience_collector() -> void:
	experience_collector = Area2D.new()
	experience_collector.collision_layer = 0
	experience_collector.collision_mask = 16 # Layer 5: Experience
	add_child(experience_collector)
	
	experience_collector.area_entered.connect(_on_experience_collector_area_entered)
	
	collection_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = collection_radius
	collection_shape.shape = circle
	experience_collector.add_child(collection_shape)

func _on_experience_collector_area_entered(area: Area2D) -> void:
	if area is ExperienceGem:
		area._start_collecting()

func _setup_invincibility_timer() -> void:
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	invincibility_timer.wait_time = invincibility_duration
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	add_child(invincibility_timer)

func _setup_dash_timer() -> void:
	dash_timer = Timer.new()
	dash_timer.one_shot = true
	dash_timer.wait_time = dash_duration
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	add_child(dash_timer)

func _setup_dash_cooldown_timer() -> void:
	dash_cooldown_timer = Timer.new()
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timer_timeout)
	add_child(dash_cooldown_timer)

func _process(_delta: float) -> void:
	if _shake_strength > 0:
		camera.offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and not _is_dashing and not _dash_on_cooldown and velocity.length() > 0:
		_start_dash()
		
	_handle_movement()
	_update_animations()
	
	# Track distance traveled
	var dist = global_position.distance_to(_last_position)
	GameManager.distance_traveled += dist
	_last_position = global_position


func _handle_movement() -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed = dash_speed if _is_dashing else speed
	velocity = direction * current_speed
	move_and_slide()

func _start_dash() -> void:
	_is_dashing = true
	dash_timer.start()
	GameManager.dashes_made += 1


func _on_dash_timer_timeout() -> void:
	_is_dashing = false
	_dash_on_cooldown = true
	dash_cooldown_timer.start(dash_cooldown)

func _on_dash_cooldown_timer_timeout() -> void:
	_dash_on_cooldown = false

func _update_animations() -> void:
	if _is_dashing:
		animated_sprite.play("dash")
		if velocity.x != 0:
			animated_sprite.flip_h = velocity.x < 0
	elif velocity.length() > 0:
		animated_sprite.play("run")
		if velocity.x != 0:
			animated_sprite.flip_h = velocity.x < 0
	else:
		animated_sprite.play("idle")

func take_damage(amount: float) -> void:
	if _is_invincible:
		return
	
	hp -= amount
	hp = max(hp, 0)
	health_changed.emit(hp, max_hp)
	
	_start_invincibility()
	_show_damage_effect()
	camera_shake(5.0, 0.5)
	# Воспроизводим звук урона
	if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
		AudioManager.play_damage()
	
	if hp <= 0:
		_die()

func _start_invincibility() -> void:
	_is_invincible = true
	invincibility_timer.start()

func _on_invincibility_timer_timeout() -> void:
	_is_invincible = false
	modulate = Color.WHITE

func _show_damage_effect() -> void:
	# Мигание при получении урона
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 0.5), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.05)
	tween.set_loops(int(invincibility_duration / 0.1))

func camera_shake(intensity: float, duration: float) -> void:
	if not camera: return
	
	if _shake_tween:
		_shake_tween.kill()
	
	_shake_strength = intensity
	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(self, "_shake_strength", 0.0, duration)

func _die() -> void:
	died.emit()

func heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
	GameManager.potions_consumed += 1


## Добавляет опыт игроку и проверяет повышение уровня
func add_experience(amount: int) -> void:
	current_exp += amount
	experience_changed.emit(current_exp, target_exp)
	
	# Проверяем повышение уровня
	while current_exp >= target_exp:
		_level_up()

func _level_up() -> void:
	current_exp -= target_exp
	level += 1
	target_exp = int(target_exp * exp_multiplier)
	
	experience_changed.emit(current_exp, target_exp)
	level_up.emit(level)
	
	# Пауза игры для выбора апгрейда
	get_tree().paused = true
