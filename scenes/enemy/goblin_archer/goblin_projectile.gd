extends Area2D
class_name EnemyProjectile

@export var speed: float = 120.0
@export var damage: float = 15.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0

func _ready() -> void:
	# Connect signals (only once)
	body_entered.connect(_on_body_entered)
	on_reuse()

func on_reuse() -> void:
	_time_alive = 0.0
	set_process(true)
	set_physics_process(true)
	# Rotation and direction setting should happen in the caller (GoblinArcher)
	# but we can reset state here if needed.

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	_time_alive += delta
	if _time_alive >= lifetime:
		ObjectPool.return_instance(self)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		ObjectPool.return_instance(self)
	elif body.collision_layer & 1: # World layer
		ObjectPool.return_instance(self)
