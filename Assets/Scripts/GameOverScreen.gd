extends CanvasLayer

@export var main_menu_scene_path: String = "res://Assets/Scenes/MainMenu.tscn"



func _on_restart_button_pressed() -> void:
		# Unpause first, then reload the current scene
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()


func _on_menu_button_pressed() -> void:
		# Unpause first, then go back to the main menu
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene_path)
	queue_free()
