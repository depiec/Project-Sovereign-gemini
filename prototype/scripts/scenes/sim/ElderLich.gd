extends CharacterBody3D

# ElderLich.gd - Magic-focused minion attracted by Library
# Automatically patrols or researches in the Library.

@export var speed = 3.0
@onready var dungeon_manager = get_parent()
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_target_grid: Vector2i = Vector2i(-1, -1)
var is_researching = false
var research_timer = 0.0

func _ready():
	add_to_group("minions")
	set_physics_process(false)
	call_deferred("setup_nav")

func setup_nav():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	if is_researching:
		research_timer += delta
		if research_timer >= 10.0:
			finish_research()
		return

	if current_target_grid == Vector2i(-1, -1):
		find_library_spot()
	
	if current_target_grid != Vector2i(-1, -1):
		move_to_library(delta)

func find_library_spot():
	# Find a Library tile to "work" in
	var library_tiles = []
	for pos in dungeon_manager.dungeon_grid.keys():
		if dungeon_manager.dungeon_grid[pos] == dungeon_manager.TileType.LIBRARY:
			library_tiles.append(pos)
	
	if library_tiles.size() > 0:
		current_target_grid = library_tiles[randi() % library_tiles.size()]

func move_to_library(_delta):
	var target_world_pos = Vector3(current_target_grid.x * 2.0, 1.0, current_target_grid.y * 2.0)
	nav_agent.target_position = target_world_pos
	
	if nav_agent.is_navigation_finished():
		start_research()
		return
		
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = (next_path_pos - global_transform.origin).normalized()
	dir.y = 0
	
	velocity = dir * speed
	move_and_slide()

func start_research():
	is_researching = true
	research_timer = 0.0
	velocity = Vector3.ZERO
	print("Elder Lich started research in Library.")

func finish_research():
	is_researching = false
	current_target_grid = Vector2i(-1, -1)
	# Grant extra MP or a scroll
	GameManager.player_state.mp = min(GameManager.player_state.mp + 50, 1000)
	print("Elder Lich finished research. MP granted.")

func get_grid_pos() -> Vector2i:
	return Vector2i(round(global_transform.origin.x / 2.0), round(global_transform.origin.z / 2.0))

func be_slapped():
	if is_researching:
		research_timer += 5.0 # Skip half research
	print("Elder Lich was slapped! Research accelerated.")
