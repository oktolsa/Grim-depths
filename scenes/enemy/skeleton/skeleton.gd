extends Enemy

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

@export var attack_cooldown: float = 1.0

var can_attack: bool = true
var attack_timer: Timer
var hitbox: Area2D

func _ready() -> void:
	super._ready() # Ensure Enemy._ready() runs to set up stats
	_setup_hitbox()
	_setup_attack_timer()

func _setup_attack_timer() -> void:
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(func(): can_attack = true)
	add_child(attack_timer)

func _setup_hitbox() -> void:
	hitbox = Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2 # Detect Player
	add_child(hitbox)
	
	var new_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0 # Very tight attack range
	new_shape.shape = circle
	hitbox.add_child(new_shape)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_animate()
	_handle_attack()

func _handle_attack() -> void:
	if not can_attack:
		return
		
	if is_instance_valid(_player):
		# Use squared distance for performance
		if global_position.distance_squared_to(_player.global_position) < 400.0: # 20.0 * 20.0
			if _player.has_method("take_damage"):
				_player.take_damage(contact_damage)
				can_attack = false
				attack_timer.start(attack_cooldown)

func _animate() -> void:
	if velocity.length() > 0:
		animation_player.play("walk")
		# Flip sprite based on movement direction
		# Assuming standard sprite facing right or left
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
	else:
		animation_player.play("idle")
