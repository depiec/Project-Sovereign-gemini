extends CharacterBody3D

# Lizardman.gd - Non-undead minion attracted by Hatchery
# Requires food to stay active. Can fight and claim tiles.

@export var speed = 5.0
@onready var dungeon_manager = get_parent()
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_target_grid: Vector2i = Vector2i(-1, -1)
var is_hungry = false
var hunger_level = 100.0

func _ready():
	add_to_group("minions")
	add_to_group("lizardmen")
	set_physics_process(false)
	call_deferred("setup_nav")

func setup_nav():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	hunger_level -= delta * 0.5 # Constant hunger
	if hunger_level < 30:
		is_hungry = true
	
	if is_hungry:
		find_food()
	elif current_target_grid == Vector2i(-1, -1):
		find_task()
	
	if current_target_grid != Vector2i(-1, -1):
		move_to_target(delta)

func find_food():
	# Move to the closest Hatchery tile
	var hatchery_tiles = []
	for pos in dungeon_manager.dungeon_grid.keys():
		if dungeon_manager.dungeon_grid[pos] == dungeon_manager.TileType.HATCHERY:
			hatchery_tiles.append(pos)
	
	if hatchery_tiles.size() > 0:
		current_target_grid = hatchery_tiles[0] # Just pick first for now

func find_task():
	# Lizardmen can claim tiles
	for pos in dungeon_manager.dungeon_grid.keys():
		if dungeon_manager.dungeon_grid[pos] == dungeon_manager.TileType.EMPTY:
			current_target_grid = pos
			return

func move_to_target(_delta):
	var target_world_pos = Vector3(current_target_grid.x * 2.0, 1.0, current_target_grid.y * 2.0)
	nav_agent.target_position = target_world_pos
	
	if nav_agent.is_navigation_finished():
		if is_hungry:
			eat_food()
		else:
			claim_tile()
		return
		
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_transform.origin).normalized()
	dir.y = 0
	velocity = dir * speed
	move_and_slide()

func eat_food():
	if GameManager.spend_resource("food", 20):
		hunger_level = 100.0
		is_hungry = false
		current_target_grid = Vector2i(-1, -1)
		print("Lizardman ate bipedal sheep. Satisfied.")

func claim_tile():
	dungeon_manager.claim_tile(current_target_grid)
	current_target_grid = Vector2i(-1, -1)

func be_slapped():
	print("Lizardman Hisses! (Fear increased)")
