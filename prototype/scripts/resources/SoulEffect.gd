extends Node3D

# SoulEffect.gd - Visual feedback for harvesting souls

var player: Node3D
var speed: float = 10.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	# Auto-destroy if it takes too long
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _process(delta):
	if player:
		var target_pos = player.global_transform.origin + Vector3(0, 1.5, 0)
		var direction = (target_pos - global_transform.origin).normalized()
		global_transform.origin += direction * speed * delta
		
		if global_transform.origin.distance_to(target_pos) < 0.5:
			# Visual pop or sound could go here
			queue_free()
