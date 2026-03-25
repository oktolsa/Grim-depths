extends Enemy
class_name Boss

@export var boss_name: String = "Bogslium the Slime"

func _ready() -> void:
	_setup_attack()
	super._ready()
	
	# Сообщаем GameManager о спавне босса
	GameManager.boss_spawned.emit(boss_name, max_hp)
	
	# Если в Main нет активного босса, этот босс становится им
	var main = get_tree().current_scene as Main
	if main and main.has_method("register_active_boss"):
		if main._current_boss == null or not is_instance_valid(main._current_boss):
			main.register_active_boss(self)

func on_reuse() -> void:
	super.on_reuse()
	can_attack = true
	if attack_timer:
		attack_timer.stop()

var can_attack: bool = true
var attack_timer: Timer

func _setup_attack() -> void:
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = 1.0 # Boss attacks every 1 second
	attack_timer.timeout.connect(func(): can_attack = true)
	add_child(attack_timer)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_handle_attack()

func _handle_attack() -> void:
	if not can_attack or not is_instance_valid(GameManager.player):
		return
		
	# Boss is large (radius ~168), attack range ~200 pixels (squared: 40000.0)
	if global_position.distance_squared_to(GameManager.player.global_position) < 40000.0:
		if GameManager.player.has_method("take_damage"):
			GameManager.player.take_damage(contact_damage)
			can_attack = false
			attack_timer.start()

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	# Если это "главный" босс, обновляем UI
	var main = get_tree().current_scene as Main
	if main and is_instance_valid(main) and main._current_boss == self:
		main.update_boss_health_ui(hp, max_hp)

func _die() -> void:
	# Если это "главный" босс, скрываем UI
	var main = get_tree().current_scene as Main
	if main and is_instance_valid(main) and main._current_boss == self:
		main.hide_boss_ui()
		
	super._die()

func _spawn_experience_gem(pos: Vector2) -> void:
	# Босс роняет "уровень" (огромный гем или несколько)
	if not experience_gem_scene:
		return
	
	var player = GameManager.player
	var exp_to_level = 100
	if player and "target_exp" in player:
		exp_to_level = player.target_exp
	
	var gem := ObjectPool.get_instance(experience_gem_scene) as ExperienceGem
	if gem:
		# Даём столько опыта, чтобы точно хватило на уровень (или просто много)
		gem.experience_value = exp_to_level
		gem.global_position = pos
		# Визуально выделяем гем босса
		gem.target_scale = Vector2(5.0, 5.0)
		gem.modulate = Color.GOLD
		
		var parent := get_parent()
		if parent:
			parent.add_child(gem)
