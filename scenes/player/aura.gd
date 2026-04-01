extends Area2D
class_name PlayerAura

## Урон ауры за одну атаку
@export var damage: float = 5.0
## Интервал между атаками в секундах
@export var attack_interval: float = 1.5:
	set(value):
		attack_interval = max(0.1, value)
		if attack_timer:
			attack_timer.wait_time = attack_interval
## Радиус ауры
@export var aura_radius: float = 50.0:
	set(value):
		aura_radius = value
		_update_collision_shape()
		queue_redraw()

## Цвет ауры
@export var aura_color: Color = Color(0.2, 0.6, 1.0, 0.3)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var particles: GPUParticles2D = $AuraParticles

func _ready() -> void:
	_setup_timer()
	_update_collision_shape()
	GameManager.register_aura(self)

func _setup_timer() -> void:
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	
	# Visual effect
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.1, 1.0).from(0.3)
	tween.tween_property(self, "modulate:a", 0.3, 1.0)

func _update_collision_shape() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = aura_radius

func _on_attack_timer_timeout() -> void:
	_deal_damage_to_enemies()

func _deal_damage_to_enemies() -> void:
	var bodies := get_overlapping_bodies()
	var hit_enemy = false
	
	for body in bodies:
		# Don't damage self (player)
		if body == owner or body == get_parent():
			continue
			
		# Improved check: for large enemies (like the Boss), we allow damage 
		# if they are at least partially overlapping the visual aura.
		var distance = global_position.distance_to(body.global_position)
		
		var enemy_radius = 16.0 # Default fallback
		if body.has_node("CollisionShape2D"):
			var shape = body.get_node("CollisionShape2D").shape
			if shape is CircleShape2D:
				# Account for scale (the boss is scaled 4x)
				enemy_radius = shape.radius * body.scale.x
		
		# Allow damage if at least 25% of the enemy's radius is inside the aura
		if distance > aura_radius + (enemy_radius * 0.75):
			continue
			
		if body.has_method("take_damage"):
			body.take_damage(damage)
			GameManager.damage_dealt += damage
			hit_enemy = true

	
	if hit_enemy and particles:
		particles.restart()
		particles.emitting = true

func _draw() -> void:
	draw_circle(Vector2.ZERO, aura_radius, aura_color)
