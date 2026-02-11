extends Node3D

# CombatLayer.gd - Combat Layer Logic
# Handles the combat loop.

var raid_data: Dictionary

func _ready():
	# Retrieve raid data from GameManager if available (passed during scene transition)
	# For prototype, we simulate it
	raid_data = {
		"enemy_type": "Worker",
		"enemy_strength": 3,
		"location": "Nazarick Entrance"
	}
	print("CombatLayer: Raid Started! Type: ", raid_data.enemy_type)
	spawn_enemies()

var enemy_count: int = 0

func _process(_delta):
	# Simple win condition check
	var current_enemies = get_tree().get_nodes_in_group("enemies")
	if current_enemies.size() == 0 and enemy_count > 0:
		show_victory()

func spawn_enemies():
	print("Spawning Enemies and Defenses...")
	
	# 1. Spawn Enemies
	var enemy_scene = load("res://scenes/combat/entities/Enemy.tscn")
	if enemy_scene:
		enemy_count = raid_data.enemy_strength
		for i in range(raid_data.enemy_strength):
			var enemy = enemy_scene.instantiate()
			add_child(enemy)
			enemy.add_to_group("enemies")
			enemy.global_transform.origin = Vector3(randf_range(-8, 8), 1.5, randf_range(-8, 8))
	
	# 2. Spawn Saved Defenses from Sim Layer
	for defense in GameManager.current_defenses:
		var instance = defense["scene"].instantiate()
		add_child(instance)
		instance.global_transform.origin = defense["pos"]
		print("CombatLayer: Spawned persistent defense: ", defense["type"])

func show_victory():
	if $HUD.has_node("VictoryPanel"): return
	
	var panel = Panel.new()
	panel.name = "VictoryPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 200)
	panel.position -= Vector2(150, 100)
	$HUD.add_child(panel)
	
	var label = Label.new()
	label.text = "SASUGA AINZ-SAMA!\nVictory is Yours."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.add_child(label)
	
	var btn = Button.new()
	btn.text = "Return to Throne Room"
	btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/strategy/MainStrategy.tscn"))
	panel.add_child(btn)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	enemy_count = 0 # Prevent multiple calls
