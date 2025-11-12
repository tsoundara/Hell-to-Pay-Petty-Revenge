extends Control

@onready var button_resume = $VBoxContainer/Button_Resume
@onready var button_restart = $VBoxContainer/Button_Restart
@onready var button_home = $VBoxContainer/Button_Home
@onready var button_quit = $VBoxContainer/Button_Quit

func _ready():
	hide()
	# Ensure pause menu still processes input while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	button_resume.pressed.connect(_on_resume_pressed)
	button_restart.pressed.connect(_on_restart_pressed)
	button_home.pressed.connect(_on_home_pressed)
	button_quit.pressed.connect(_on_quit_pressed)

func _on_resume_pressed():
	get_tree().paused = false
	hide()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_home_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenu.tscn") # change this path!

func _on_quit_pressed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("pause"):
		if visible:
			get_tree().paused = false
			hide()
		else:
			get_tree().paused = true
			show()
