extends CanvasLayer

@export var main_menu_scene_path: String = "res://Assets/Scenes/MainMenu.tscn"

func _on_menu_button_pressed() -> void:
	# 1. Remove the Win Screen instance
	queue_free()
	
	# 2. Unpause the game (if it was paused)
	get_tree().paused = false
	
	# 3. Change to the main menu scene
	get_tree().change_scene_to_file(main_menu_scene_path)
