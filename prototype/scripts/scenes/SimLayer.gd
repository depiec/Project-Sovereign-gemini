extends Node3D

# SimLayer.gd - Updated for Mouse-Drag Interaction, Reinforced Walls, and Possession

@onready var dungeon_manager = $NavigationRegion3D/DungeonManager
@onready var camera = $Camera3D
@onready var minion_label: Label = %MinionCountLabel

enum InteractionMode { DIG, CLAIM, BUILD_TREASURY, BUILD_LIBRARY, SLAP, BUILD_REINFORCED, POSSESS, BUILD_HATCHERY }
var current_mode = InteractionMode.DIG

var is_dragging = false
var drag_mode_is_adding = true # True to mark, False to unmark
var last_grid_pos = Vector2i(-1, -1)
var possessed_node: CharacterBody3D = null

func _ready():
	print("SimLayer: Dungeon Keeper mode active.")
	dungeon_manager.stats_updated.connect(_on_dungeon_stats_updated)

func _process(_delta):
	# Periodically update minion counts
	var workers = get_tree().get_nodes_in_group("workers").size()
	var liches = get_tree().get_nodes_in_group("liches").size()
	minion_label.text = "Workers: %d | Liches: %d" % [workers, liches]

func _on_dungeon_stats_updated(stats: Dictionary):
	print("Dungeon Stats: ", stats)

func _input(event):
	if possessed_node:
		if event.is_action_pressed("ui_cancel"):
			stop_possession()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if is_dragging:
				var pos = get_grid_pos(event.position)
				if current_mode == InteractionMode.DIG:
					drag_mode_is_adding = !dungeon_manager.digging_queue.has(pos)
				else:
					drag_mode_is_adding = true
				
				handle_interaction(pos, false)
				last_grid_pos = pos
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_interaction(get_grid_pos(event.position), true)

	elif event is InputEventMouseMotion and is_dragging:
		var pos = get_grid_pos(event.position)
		if pos != last_grid_pos:
			handle_interaction(pos, false)
			last_grid_pos = pos

func get_grid_pos(mouse_pos: Vector2) -> Vector2i:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	var t = -from.y / (to.y - from.y)
	var hit_pos = from + (to - from) * t
	return Vector2i(int(round(hit_pos.x / 2.0)), int(round(hit_pos.z / 2.0)))

func handle_interaction(grid_pos: Vector2i, is_right_click: bool):
	if is_right_click or current_mode == InteractionMode.SLAP:
		dungeon_manager.slap_at(grid_pos)
		return
	
	if current_mode == InteractionMode.POSSESS:
		try_possession()
		return
	
	match current_mode:
		InteractionMode.DIG:
			dungeon_manager.set_digging_mark(grid_pos, drag_mode_is_adding)
		InteractionMode.BUILD_TREASURY:
			dungeon_manager.build_room(grid_pos, dungeon_manager.TileType.TREASURY)
		InteractionMode.BUILD_LIBRARY:
			dungeon_manager.build_room(grid_pos, dungeon_manager.TileType.LIBRARY)
		InteractionMode.BUILD_REINFORCED:
			dungeon_manager.build_reinforced_wall(grid_pos)
		InteractionMode.BUILD_HATCHERY:
			dungeon_manager.build_room(grid_pos, dungeon_manager.TileType.HATCHERY)

func try_possession():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 # characters
	
	var result = space_state.intersect_ray(query)
	if result:
		var target = result.collider
		if target.is_in_group("workers") or target.is_in_group("liches"):
			start_possession(target)

func start_possession(target: CharacterBody3D):
	print("Possessing: ", target.name)
	possessed_node = target
	GameManager.player_state.possessed_minion = target
	camera.current = false
	if target.has_method("be_possessed"):
		target.be_possessed()
	$UI.visible = false

func stop_possession():
	print("Stopping possession of: ", possessed_node.name)
	if possessed_node.has_method("be_unpossessed"):
		possessed_node.be_unpossessed()
	possessed_node = null
	GameManager.player_state.possessed_minion = null
	camera.current = true
	$UI.visible = true

func _on_DigModeButton_pressed():
	current_mode = InteractionMode.DIG
	print("Mode: Dig")

func _on_SlapButton_pressed():
	current_mode = InteractionMode.SLAP
	print("Mode: Slap")

func _on_ReinforcedButton_pressed():
	current_mode = InteractionMode.BUILD_REINFORCED
	print("Mode: Build Reinforced")

func _on_HatcheryButton_pressed():
	current_mode = InteractionMode.BUILD_HATCHERY
	print("Mode: Build Hatchery")

func _on_PossessButton_pressed():
	current_mode = InteractionMode.POSSESS
	print("Mode: Possess")

func _on_TreasuryButton_pressed():
	current_mode = InteractionMode.BUILD_TREASURY
	print("Mode: Build Treasury")

func _on_LibraryButton_pressed():
	current_mode = InteractionMode.BUILD_LIBRARY
	print("Mode: Build Library")

func _on_StartCombatButton_pressed():
	var raid_data = {"enemy_type": "Worker", "enemy_strength": 5, "location": "Nazarick"}
	GameManager.start_combat(raid_data)
