extends Node

# GameManager.gd - Global Singleton
# Manages the transition between Strategy, Sim, and Combat layers.

signal sasuga_changed(new_value)
signal resources_updated(new_resources)
signal raid_started(raid_data)

# --- Game State ---

var world_state = {
	"territories": {
		"CarneVillage": {"pos": Vector2i(0, 0), "owner": "Neutral", "type": "Village"},
		"ERantel": {"pos": Vector2i(1, 0), "owner": "ReEstize", "type": "City"},
		"KatzePlains": {"pos": Vector2i(1, 1), "owner": "Neutral", "type": "Wasteland"},
		"Arwintar": {"pos": Vector2i(2, 0), "owner": "Baharuth", "type": "Capital"},
		"Nazarick": {"pos": Vector2i(0, 1), "owner": "Nazarick", "type": "Tomb"}
	},
	"factions": {
		"ReEstize": {"status": "Neutral", "threat_level": 1},
		"Baharuth": {"status": "Friendly", "threat_level": 2},
		"Slane": {"status": "Hostile", "threat_level": 5}
	},
	"current_turn": 1
}

var nazarick_state = {
	"resources": {
		"gold": 1000000, # YGGDRASIL Gold
		"souls": 0,
		"materials": 500,
		"food": 100
	},
	"floors": {
		"floor_1": {"defense": 100, "traps": []},
		"floor_6": {"defense": 500, "mobs": []}
	}
}

enum Persona { OVERLORD, MOMON }

var player_state = {
	"mp": 99999,
	"hp": 99999,
	"known_spells": [], # Array of SpellResources
	"sasuga_meter": 0.5, # 0.0 = Panic, 1.0 = Supreme Being
	"current_persona": Persona.OVERLORD,
	"active_guardian": "None", # Albedo or Shalltear
	"possessed_minion": null
}

# Entities placed during Sim Layer to be spawned in Combat Layer
var current_defenses = [] # Array of Dictionary { "scene": PackedScene, "pos": Vector3, "type": String }

func _ready():
	# Load starting spells
	var fireball = load("res://resources/spells/Fireball.tres")
	if fireball:
		player_state.known_spells.append(fireball)
	
	var fallen_down = load("res://resources/spells/FallenDown.tres")
	if fallen_down:
		player_state.known_spells.append(fallen_down)
		
	print("GameManager: Ainz initialized with ", player_state.known_spells.size(), " spells.")

func update_sasuga(amount: float):
	player_state.sasuga_meter = clamp(player_state.sasuga_meter + amount, 0.0, 1.0)
	sasuga_changed.emit(player_state.sasuga_meter)
	print("Sasuga Meter updated to: ", player_state.sasuga_meter)

func add_resource(type: String, amount: int):
	if nazarick_state.resources.has(type):
		nazarick_state.resources[type] += amount
		resources_updated.emit(nazarick_state.resources)
		print("Resource added: ", type, " +", amount)

func spend_resource(type: String, amount: int) -> bool:
	if nazarick_state.resources.has(type) and nazarick_state.resources[type] >= amount:
		nazarick_state.resources[type] -= amount
		resources_updated.emit(nazarick_state.resources)
		print("Resource spent: ", type, " -", amount)
		return true
	print("Not enough resources: ", type)
	return false

func trigger_raid(raid_data: Dictionary):
	print("Raid Started: ", raid_data)
	raid_started.emit(raid_data)
	get_tree().change_scene_to_file("res://scenes/sim/SimLayer.tscn")

func start_combat(enemy_data: Dictionary):
	print("Combat Started against: ", enemy_data)
	get_tree().change_scene_to_file("res://scenes/combat/CombatLayer.tscn")
