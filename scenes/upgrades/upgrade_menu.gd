extends Control

var current_upgrades = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$ButtonContainer/UpgradeButton1.pressed.connect(_on_UpgradeButton1_pressed)
	$ButtonContainer/UpgradeButton2.pressed.connect(_on_UpgradeButton2_pressed)
	$ButtonContainer/UpgradeButton3.pressed.connect(_on_UpgradeButton3_pressed)
	hide()
	
func show_upgrades() -> void:
	current_upgrades = GameManager.get_random_upgrades(3)
	
	for i in range(3):
		var button = get_node("ButtonContainer/UpgradeButton" + str(i+1))
		if i < current_upgrades.size():
			var u_name = tr(current_upgrades[i]["name"])
			var u_desc = tr(current_upgrades[i]["description"])
			button.text = u_name + "\n\n" + u_desc
			button.disabled = false
			button.show()
		else:
			button.hide()
	
	show()
	get_tree().paused = true

func _on_button_pressed(index):
	if index >= current_upgrades.size():
		return
	
	var upgrade = current_upgrades[index]
	GameManager.apply_upgrade(upgrade)
	
	hide()
	get_tree().paused = false

func _on_UpgradeButton1_pressed():
	_on_button_pressed(0)

func _on_UpgradeButton2_pressed():
	_on_button_pressed(1)

func _on_UpgradeButton3_pressed():
	_on_button_pressed(2)