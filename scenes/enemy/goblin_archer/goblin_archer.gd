extends Enemy
class_name GoblinArcher

@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 2.0
@export var attack_range: float = 250.0
@export var stop_range: float = 180.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var shoot_timer: Timer

var can_shoot: bool = true

func _ready() -> void:
	# Устанавливаем базовые параметры перед вызовом super._ready()
	base_max_hp = 70.0
	base_speed = 50.0
	base_contact_damage = 15.0
	experience_value = 25
	
	_setup_shoot_timer()
	super._ready()

func on_reuse() -> void:
	super.on_reuse()
	can_shoot = true
	if shoot_timer:
		shoot_timer.stop()

func _setup_shoot_timer() -> void:
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.timeout.connect(func(): can_shoot = true)
	add_child(shoot_timer)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = GameManager.player
		if not _player: return

	var dist_sq = global_position.distance_squared_to(_player.global_position)
	
	# Хибернация
	if dist_sq > HIBERNATION_DISTANCE * HIBERNATION_DISTANCE:
		_is_hibernating = true
		return
	_is_hibernating = false
	
	var stop_range_sq = stop_range * stop_range
	var attack_range_sq = attack_range * attack_range
	
	if dist_sq > stop_range_sq:
		_move_towards_player(delta)
	else:
		# Сохраняем логику CharacterBody2D если стоим (для отталкивания)
		velocity = Vector2.ZERO
		move_and_slide()
	
	if dist_sq < attack_range_sq and can_shoot:
		_shoot()
	
	_animate()

func _shoot() -> void:
	if not projectile_scene: return
		
	can_shoot = false
	shoot_timer.start(shoot_cooldown)
	
	var proj = ObjectPool.get_instance(projectile_scene) as EnemyProjectile
	proj.global_position = global_position
	proj.direction = global_position.direction_to(_player.global_position)
	proj.rotation = proj.direction.angle()
	proj.damage = contact_damage
	
	var entities = get_parent()
	if entities:
		entities.add_child(proj)
	else:
		get_tree().current_scene.add_child(proj)

func _animate() -> void:
	if velocity.length() > 0:
		animation_player.play("walk")
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
	else:
		animation_player.play("idle")
		# Even if standing, look at player
		if _player and is_instance_valid(_player):
			if (_player.global_position.x - global_position.x) < 0:
				sprite.flip_h = true
			else:
				sprite.flip_h = false
