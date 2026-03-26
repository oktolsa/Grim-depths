extends Node

## Глобальная система пула объектов для оптимизации на мобильных устройствах
## Позволяет повторно использовать объекты вместо постоянного создания и удаления

# Словарь для хранения пулов: { "path_to_scene": [instances] }
var _pools: Dictionary = {}

## Получить экземпляр из пула или создать новый
func get_instance(scene: PackedScene) -> Node:
	if not scene:
		push_error("ObjectPool: Attempted to get instance of null scene")
		return null
		
	var path = scene.resource_path
	if not _pools.has(path):
		_pools[path] = []
	
	var instance: Node
	if _pools[path].size() > 0:
		instance = _pools[path].pop_back()
		if instance.has_meta("returning_to_pool"):
			instance.set_meta("returning_to_pool", false)
	else:
		instance = scene.instantiate()
		instance.set_meta("scene_path", path)
	
	# Активация обработки произойдет автоматически при добавлении в дерево,
	# но мы убеждаемся, что флаги установлены корректно.
	instance.set_process(true)
	instance.set_physics_process(true)
	
	if instance.has_method("on_reuse"):
		instance.on_reuse()
		
	return instance

## Вернуть экземпляр в пул
func return_instance(instance: Node) -> void:
	if not is_instance_valid(instance):
		return
		
	if instance.get_meta("returning_to_pool", false):
		return
	instance.set_meta("returning_to_pool", true)
	
	instance.set_process(false)
	instance.set_physics_process(false)
	
	call_deferred("_finalize_return", instance)

func _finalize_return(instance: Node) -> void:
	if not is_instance_valid(instance):
		return
		
	var path = ""
	if instance.has_meta("scene_path"):
		path = instance.get_meta("scene_path")
	else:
		# Фолбек, если метаданные не установлены (например, если объект был создан не через пул)
		path = instance.scene_file_path
		
	if path == "":
		push_warning("ObjectPool: Instance has no scene path, freeing it instead: " + str(instance))
		instance.queue_free()
		return
		
	if not _pools.has(path):
		_pools[path] = []
		
	# Убираем из дерева сцены
	if instance.get_parent():
		instance.get_parent().remove_child(instance)
	
	_pools[path].push_back(instance)

## Предварительное наполнение пула для избежания фризов во время игры
func pre_populate(scene: PackedScene, amount: int) -> void:
	if not scene: return
	
	var path = scene.resource_path
	if not _pools.has(path):
		_pools[path] = []
		
	for i in range(amount):
		var instance = scene.instantiate()
		instance.set_meta("scene_path", path)
		instance.set_meta("returning_to_pool", true)
		instance.set_process(false)
		instance.set_physics_process(false)
		_pools[path].push_back(instance)
	
	print("ObjectPool: Pre-populated ", amount, " instances of ", path.get_file())
