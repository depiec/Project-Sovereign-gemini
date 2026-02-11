extends Control

# WorldMap.gd - Custom draw for the Strategy Map

signal territory_selected(territory_name)

var tile_size = 100.0
var territories = {}

func _ready():
	territories = GameManager.world_state.territories
	queue_redraw()

func _draw():
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.1, 0.05))
	
	# Draw tiles
	for name in territories.keys():
		var data = territories[name]
		var pos = Vector2(data.pos.x * tile_size, data.pos.y * tile_size) + Vector2(tile_size/2, tile_size/2)
		
		# Set color based on owner
		var color = Color(0.5, 0.5, 0.5) # Grey for Neutral
		match data.owner:
			"Nazarick": color = Color(0.4, 0, 0.6) # Purple
			"ReEstize": color = Color(0.8, 0.8, 0) # Yellow
			"Baharuth": color = Color(0.8, 0, 0) # Red
			
		draw_circle(pos, tile_size * 0.4, color)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-30, 0), name, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_pos = Vector2i(int(event.position.x / tile_size), int(event.position.y / tile_size))
		for name in territories.keys():
			if territories[name].pos == clicked_pos:
				print("Selected Territory: ", name)
				territory_selected.emit(name)
				return
