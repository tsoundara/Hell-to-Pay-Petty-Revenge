extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_kill_zone_body_entered(body: Node2D) -> void:
	# 1. Check if the body is the player
	if body.is_in_group("player"):
		# Trigger the player's death/respawn logic
		# You will need to define this function in your player script
		body.take_damage_and_respawn()
		# OR: Get the game to restart
		# get_tree().reload_current_scene()
	# 2. Check if the body is an enemy
	elif body.is_in_group("enemies"):
		# Enemies should also be removed if they fall into the gap
		# Check if the enemy has a 'die' function or simply queue_free it
		if body.has_method("die"):
			body.die()
		else:
			body.queue_free()
			
	# Note: Using groups ("player", "enemy") is much safer than checking names.
