extends CharacterBody3D

# ElderLich.gd - Magic-focused minion attracted by Library
# Can be possessed by the player.

@export var speed = 3.0
@onready var dungeon_manager = get_parent()
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_target_grid: Vector2i = Vector2i(-1, -1)
var is_researching = false
var research_timer = 0.0
var is_possessed = false

func _ready():
	add_to_group("minions")
	add_to_group("liches")
	set_physics_process(false)
	call_deferred("setup_nav")

func setup_nav():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	if is_possessed:
		handle_possessed_movement(delta)
		return

	if is_researching:
		research_timer += delta
		if research_timer >= 10.0:
			finish_research()
		return

	if current_target_grid == Vector2i(-1, -1):
		find_library_spot()
	
	if current_target_grid != Vector2i(-1, -1):
		move_to_library(delta)

func handle_possessed_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir = Vector3(input_dir.x, 0, input_dir.y).normalized()
	velocity = dir * speed * 2.0
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	if dir.length() > 0.1:
		look_at(global_transform.origin + dir, Vector3.UP)
	if Input.is_action_just_pressed("mouse_left"):
		print("Elder Lich: Casting Soul Eater!")

func be_possessed():
	is_possessed = true
	is_researching = false
	current_target_grid = Vector2i(-1, -1)
	if has_node("PossessionCamera"):
		get_node("PossessionCamera").current = true

func be_unpossessed():
	is_possessed = false
	if has_node("PossessionCamera"):
		get_node("PossessionCamera").current = false

func find_library_spot():
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

func finish_research():
	is_researching = false
	current_target_grid = Vector2i(-1, -1)
	GameManager.player_state.mp = min(GameManager.player_state.mp + 50, 1000)

func get_grid_pos() -> Vector2i:
	return Vector2i(round(global_transform.origin.x / 2.0), round(global_transform.origin.z / 2.0))

func be_slapped():
	if is_researching:
		research_timer += 5.0
	print("Elder Lich was slapped!")