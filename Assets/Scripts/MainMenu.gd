extends CanvasLayer

@onready var play_button = $Control/VBoxContainer/Button_Play
@onready var quit_button = $Control/VBoxContainer/Button_Quit

func _ready():
	pass



func _on_button_quit_pressed() -> void:
	get_tree().quit()


func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/levels/start_level.tscn") # Change to your level path
