extends Area2D

# ----------------------------------------------------
# --- Exported Variables ---
# ----------------------------------------------------

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
	animated_sprite.play("Idle")
	
	# Ensure the next level path is set.
	if next_level_path.is_empty():
		print("ERROR: 'next_level_path' is empty. Set in the Inspector")

func _process(_delta: float) -> void:
	if is_player_in_range and Input.is_action_just_pressed("ui_accept"):
		# The door attempts transition immediately upon interaction.
		attempt_level_transition()

# ----------------------------------------------------
# --- Signal Handlers ---
# ----------------------------------------------------

# Called when the player enters the Area2D
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = true
		player_node = body
		print("Player is near the door")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = false
		player_node = null

# ----------------------------------------------------
# --- Core Logic ---
# ----------------------------------------------------

func attempt_level_transition() -> void:
	animated_sprite.play("Open")
	collision_shape.set_deferred("disabled", true) # Disable collision so player can pass through

	await animated_sprite.animation_finished
	load_next_level()

func load_next_level() -> void:
	if not next_level_path.is_empty() and FileAccess.file_exists(next_level_path):
		# Stop everything to prevent any lingering actions from the old scene
		get_tree().paused = false 
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("ERROR: Cannot load next level. Path is invalid: " + next_level_path)
		get_tree().reload_current_scene()
