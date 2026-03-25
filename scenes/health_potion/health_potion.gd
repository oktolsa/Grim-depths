extends Area2D
class_name HealthPotion

## Amount of health restored
@export var heal_amount: float = 25.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Ensure the texture is set
	if sprite:
		sprite.texture = load("res://Assets/DebtsInTheDepthsAssets/health_potion.png")
	
	body_entered.connect(_on_body_entered)
	
	# Subtle floating animation
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -5.0, 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 5.0, 1.2).set_trans(Tween.TRANS_SINE)
	
	# Appearance animation
	scale = Vector2.ZERO
	var appear_tween = create_tween()
	appear_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.4)
	appear_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("heal"):
			# Only pick up if player is not at full health? 
			# Actually, usually in survivors-like you pick it up anyway, or wait.
			# Let's check HP.
			if body.hp < body.max_hp:
				body.heal(heal_amount)
				_collect()

func _collect() -> void:
	# Disable collisions to prevent double trigger
	collision.set_deferred("disabled", true)
	
	# Visual effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().kill()
	
	# Wait for animation then free
	get_tree().create_timer(0.2).timeout.connect(queue_free)
