extends Control

# MainStrategy.gd - Strategy Layer Logic
# Handles the UI interaction and calls the GameManager.

@onready var resource_label: Label = $VBoxContainer/ResourceLabel
@onready var raid_button: Button = $VBoxContainer/RaidButton

@onready var sasuga_panel: Panel = $SasugaPanel
@onready var guardian_panel: Panel = $GuardianPanel

func _ready():
	# Update resource display initially
	update_resource_display(GameManager.nazarick_state.resources)
	
	# Connect to GameManager signals to update the UI
	GameManager.resources_updated.connect(_on_resources_updated)
	GameManager.raid_started.connect(_on_raid_started)
	
	# Hide Panels initially
	sasuga_panel.visible = false
	guardian_panel.visible = false

func _on_GuardianButton_pressed():
	guardian_panel.visible = true

func _on_AlbedoButton_pressed():
	GameManager.player_state.active_guardian = "Albedo"
	print("Guardian Selected: Albedo")
	guardian_panel.visible = false

func _on_ShalltearButton_pressed():
	GameManager.player_state.active_guardian = "Shalltear"
	print("Guardian Selected: Shalltear")
	guardian_panel.visible = false

func _on_resources_updated(new_resources: Dictionary):
	update_resource_display(new_resources)

func update_resource_display(resources: Dictionary):
	resource_label.text = "Gold: %d | Souls: %d | Materials: %d" % [
		resources["gold"],
		resources["souls"],
		resources["materials"]
	]

func _on_RaidButton_pressed():
	# Instead of triggering the raid immediately, open the Sasuga Panel
	print("Simulating Demiurge Proposal...")
	sasuga_panel.visible = true

func _on_Option1Button_pressed():
	print("Selected: 'Umu, exactly as I thought.' (High Cost, High Buff)")
	GameManager.update_sasuga(0.1)
	GameManager.spend_resource("gold", 500) # Cost for "perfect plan"
	sasuga_panel.visible = false
	start_raid()

func _on_Option2Button_pressed():
	print("Selected: 'Perhaps we should consider...' (Risky)")
	# 50% chance to fail the Sasuga check
	if randf() > 0.5:
		GameManager.update_sasuga(-0.2)
		print("Demiurge looks confused. Sasuga dropped!")
	else:
		GameManager.update_sasuga(0.05)
		print("Demiurge: 'Sasuga Ainz-sama! Improved even my plan!'")
	sasuga_panel.visible = false
	start_raid()

func _on_Option3Button_pressed():
	print("Selected: 'I shall leave the details to you.' (Low Cost, Random Events)")
	# Randomly generates resources or problems
	GameManager.add_resource("materials", 100)
	sasuga_panel.visible = false
	start_raid()

func start_raid():
	var raid_data = {
		"enemy_type": "Worker",
		"enemy_strength": 3,
		"location": "Nazarick Entrance"
	}
	GameManager.trigger_raid(raid_data)

func _on_raid_started(_raid_data):
	# In a real game, this would transition to the Sim Layer scene.
	# For prototype, we just log it.
	print("MainStrategy: Raid started! Preparing defenses...")
