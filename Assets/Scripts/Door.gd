extends Area2D

# ----------------------------------------------------
# --- Exported Variables ---
# ----------------------------------------------------

# Set the path to the next scene (e.g., "res://Assets/Scenes/level_2.tscn")
@export var next_level_path: String = ""

# ----------------------------------------------------
# --- Node References & State ---
# ----------------------------------------------------

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_player_in_range: bool = false
var player_node: Node = null

# ----------------------------------------------------
# --- Initialization & Input Polling ---
# ----------------------------------------------------

func _ready() -> void:
	animated_sprite.play("Idle") # Assuming "Idle" is the closed/default state
	
	# CRITICAL: Ensure the next level path is set.
	if next_level_path.is_empty():
		print("ERROR: Door 'next_level_path' is empty. Set it in the Inspector!")

# 💡 FIX: We move the input check to _process. This function runs every frame
# and uses the global Input singleton, which reliably prevents the crash 
# from raw InputEvent types.
func _process(_delta: float) -> void:
	# Check if the player is in range AND pressed the interact button (using Input singleton)
	if is_player_in_range and Input.is_action_just_pressed("ui_accept"):
		# The door attempts transition immediately upon interaction.
		attempt_level_transition()

# Removed: func _input(event: InputEvent) -> void: to prevent mouse motion crash.

# ----------------------------------------------------
# --- Signal Handlers ---
# ----------------------------------------------------

# Called when the player (or any physics body) enters the Area2D
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = true
		player_node = body
		print("Player is near the door. Press 'Interact' (or its keybind)!")
		# Optional: Show a UI prompt above the door here (e.g., 'E to Interact')

# Called when the player exits the Area2D
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = false
		player_node = null
		# Optional: Hide the UI prompt here

# ----------------------------------------------------
# --- Core Logic ---
# ----------------------------------------------------

func attempt_level_transition() -> void:
	# 1. Start the door opening animation
	animated_sprite.play("Open") # Assuming "Open" is a one-shot animation
	collision_shape.set_deferred("disabled", true) # Disable collision so player can pass

	# 2. Wait for the animation to finish
	await animated_sprite.animation_finished
	
	# 3. Load the next scene
	load_next_level()

func load_next_level() -> void:
	if not next_level_path.is_empty() and FileAccess.file_exists(next_level_path):
		# Stop everything to prevent any lingering actions from the old scene
		get_tree().paused = false 
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("ERROR: Cannot load next level. Path is invalid: " + next_level_path)
		# Fallback: maybe reload the current scene, or go to main menu
		get_tree().reload_current_scene()
