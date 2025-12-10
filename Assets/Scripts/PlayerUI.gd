extends CanvasLayer

@onready var health_value_label: Label = %HealthValue
@onready var score_value_label: Label = %ScoreValue

# Variables to store max health and score 
var max_health: int = 0
var current_score: int = 0

# --- Health Management ---

func initialize_ui(max_hp: int, initial_score: int = 0) -> void:
	# Called by the Player script's _ready() function at the start of the game.
	max_health = max_hp
	current_score = initial_score
	
	# Ensure the label node was found before trying to set its text
	if not is_instance_valid(health_value_label):
		print("UI ERROR: health_value_label is null. Check node path in PlayerUI.gd.")
		return
		
	# Update the UI to show initial state (full health, zero score)
	update_health(max_health)
	update_score(current_score)

func update_health(new_health: int) -> void:
	# Called by Player.gd whenever the player's health changes (takes damage, heals).
	
	# Prevent crash if the node is null
	if not is_instance_valid(health_value_label):
		print("UI ERROR: Cannot update health, health_value_label is null.")
		return
		
	health_value_label.text = str(new_health) + " / " + str(max_health)

# --- Score Management (Placeholder) ---

func update_score(new_score: int) -> void:
	if not is_instance_valid(score_value_label):
		print("UI ERROR: Cannot update score, score_value_label is null.")
		return
		
	# This part is ready to be called by enemies or collectibles when the 
	# player gains points.
	current_score = new_score
	score_value_label.text = str(new_score)
