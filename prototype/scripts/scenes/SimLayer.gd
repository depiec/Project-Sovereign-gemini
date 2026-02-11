extends Node3D

# SimLayer.gd - Updated for Mouse-Drag Interaction

@onready var dungeon_manager = $DungeonManager
@onready var camera = $Camera3D

enum InteractionMode { DIG, CLAIM, BUILD_TREASURY, BUILD_LIBRARY, SLAP }
var current_mode = InteractionMode.DIG

var is_dragging = false
var drag_mode_is_adding = true # True to mark, False to unmark
var last_grid_pos = Vector2i(-1, -1)

func _ready():
	print("SimLayer: Dungeon Keeper mode active.")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if is_dragging:
				var pos = get_grid_pos(event.position)
				# Determine if we are painting or erasing based on first tile
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
	
	# Intersection with plane Y=0
	var t = -from.y / (to.y - from.y)
	var hit_pos = from + (to - from) * t
	
	var grid_x = int(round(hit_pos.x / 2.0))
	var grid_z = int(round(hit_pos.z / 2.0))
	return Vector2i(grid_x, grid_z)

func handle_interaction(grid_pos: Vector2i, is_right_click: bool):
	if is_right_click or current_mode == InteractionMode.SLAP:
		dungeon_manager.slap_at(grid_pos)
		return
	
	match current_mode:
		InteractionMode.DIG:
			dungeon_manager.set_digging_mark(grid_pos, drag_mode_is_adding)
		InteractionMode.BUILD_TREASURY:
			dungeon_manager.build_room(grid_pos, dungeon_manager.TileType.TREASURY)
		InteractionMode.BUILD_LIBRARY:
			dungeon_manager.build_room(grid_pos, dungeon_manager.TileType.LIBRARY)

func _on_DigModeButton_pressed():
	current_mode = InteractionMode.DIG
	print("Mode: Dig")

func _on_SlapButton_pressed():
	current_mode = InteractionMode.SLAP
	print("Mode: Slap")

func _on_TreasuryButton_pressed():
	current_mode = InteractionMode.BUILD_TREASURY
	print("Mode: Build Treasury")

func _on_LibraryButton_pressed():
	current_mode = InteractionMode.BUILD_LIBRARY
	print("Mode: Build Library")

func _on_StartCombatButton_pressed():
	var raid_data = {
		"enemy_type": "Worker",
		"enemy_strength": 5,
		"location": "Nazarick"
	}
	GameManager.start_combat(raid_data)
