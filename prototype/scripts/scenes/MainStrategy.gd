extends Control

# MainStrategy.gd - Strategy Layer Logic
# Handles the UI interaction and calls the GameManager.

@onready var resource_label: Label = $VBoxContainer/ResourceLabel
@onready var raid_button: Button = $VBoxContainer/RaidButton

@onready var sasuga_panel: Panel = $SasugaPanel
@onready var guardian_panel: Panel = $GuardianPanel
@onready var operations_panel: Panel = $OperationsPanel
@onready var target_label: Label = %TargetLabel

var selected_territory = ""

func _ready():
	# Update resource display initially
	update_resource_display(GameManager.nazarick_state.resources)
	
	# Connect to GameManager signals to update the UI
	GameManager.resources_updated.connect(_on_resources_updated)
	GameManager.raid_started.connect(_on_raid_started)
	
	# Connect WorldMap
	$WorldMap.territory_selected.connect(_on_territory_selected)
	
	# Hide Panels initially
	sasuga_panel.visible = false
	guardian_panel.visible = false
	operations_panel.visible = false

func _on_territory_selected(t_name):
	selected_territory = t_name
	target_label.text = "Target: " + t_name
	operations_panel.visible = true

func _on_SpyButton_pressed():
	print("Operation: Spying on ", selected_territory)
	GameManager.spend_resource("gold", 100)
	# Success chance logic could go here
	print("Hanzo reports: Garrison is weak.")
	operations_panel.visible = false

func _on_WarButton_pressed():
	print("Operation: Declaring War on ", selected_territory)
	sasuga_panel.visible = true # Open Sasuga panel for the invasion plan
	operations_panel.visible = false

func _on_AnnexButton_pressed():
	print("Operation: Annexing ", selected_territory)
	GameManager.update_sasuga(0.05)
	# Update world state
	GameManager.world_state.territories[selected_territory].owner = "Nazarick"
	$WorldMap.queue_redraw()
	operations_panel.visible = false

func _on_CloseOpButton_pressed():
	operations_panel.visible = false

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
