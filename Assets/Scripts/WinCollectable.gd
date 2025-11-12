extends Area2D

# Connect the body_entered signal from the editor to this function!
func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is the player (assuming they are in the "player" group)
	if body.is_in_group("player"):
		# The player must have a win() function
		if body.has_method("win"):
			body.win()
			# Once collected, remove the item from the scene
			queue_free()
