extends Resource

class_name SpellResource

# SpellResource.gd - Custom Resource for Spells
# Defines the core properties of a spell, used by the Ability System.

@export var spell_name: String
@export var spell_tier: int = 1
@export var mana_cost: int = 10
@export var cooldown: float = 1.0
@export var description: String
@export var cast_time: float = 0.0 # 0.0 for instant cast
@export var is_super_tier: bool = false
@export var projectile_scene: PackedScene # The visual scene to spawn (e.g., Fireball.tscn)

# Optional: Add methods for complex logic
func get_spell_info() -> String:
	return "Spell: %s (Tier %d) - %d MP - Cooldown: %.1fs" % [spell_name, spell_tier, mana_cost, cooldown]
