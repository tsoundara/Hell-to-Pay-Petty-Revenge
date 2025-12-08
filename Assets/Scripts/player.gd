class_name Player
extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_health: int = 5
var current_health: int
@export var respawn_point_position: Vector2 = Vector2.ZERO # Default to (0, 0)
@export var attack_offset_x: float = 20.0 # Set the base X offset (facing right)
@export var game_over_screen_scene: PackedScene
@export var win_screen_scene: PackedScene
@onready var ui: Node = %PlayerUI

var default_zoom := Vector2(1.0, 1.0)
var zoomed_in := Vector2(2.0, 2.0)
@onready var camera: Camera2D = $Camera2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

var is_attacking: bool = false
var direction: float = 0.0 # Store the current input direction

func _input(event: InputEvent) -> void:
	# Only allow the attack input if the animation is not currently playing
	if event.is_action_pressed("Attack") and not is_attacking:
		is_attacking = true
		animated_sprite.play("Attack")
		# Activate the hitbox when the animation starts
		attack_area.monitoring = true
		
	# Check dialog progress
	if event.is_action_pressed("check_progress"):
		print("Letters done:", Player.mark_interacted("letters_dialog"))
		print("TV done:", Player.mark_interacted("tv_dialog"))
		print("Both done:", Player.has_interacted_all(["letters_dialog", "tv_dialog"]))

func _ready() -> void:
	# Current health must be set BEFORE initializing the UI!
	current_health = max_health
	
	# This ensures the health label shows "5 / 5" at the start of the game.
	if is_instance_valid(ui) and ui.has_method("initialize_ui"):
		# We now pass the current health and score (0) to initialize the UI.
		# The UI is initialized every time the Player scene loads.
		ui.initialize_ui(max_health)
	else:
		print("ERROR: Player UI node (%PlayerUI) not found or script is missing!")
	
	# Initialize attack area position based on initial direction (0)
	attack_area.position.x = attack_offset_x * 1.0 # Assume initial direction is positive 1
	
	var current_scene_name = get_tree().current_scene.name
	print(current_scene_name)
	if ((current_scene_name == "Start_level") or (current_scene_name == "CommissionersOffice")):
		camera.zoom = zoomed_in
	else:
		camera.zoom = default_zoom

func take_damage(amount: int, knockback_force: Vector2) -> void:
	current_health -= amount
	#Ensure health doesn't go below zero for UI integrity
	if current_health < 0:
		current_health = 0
		
	# UPDATE UI DISPLAY ON DAMAGE
	# This call tells the UI script to update the number immediately.
	if is_instance_valid(ui) and ui.has_method("update_health"):
		ui.update_health(current_health)
		
	# Apply knockback
	velocity = knockback_force
	# Optional: flash red or play hurt animation
	flash_red()
	if current_health <= 0:
		die()

# Start area dialog tracking
static var interacted_objects = []

static func mark_interacted(key: String):
	if key not in interacted_objects:
		interacted_objects.append(key)
		print("Marked as interacted:", key)

static func has_interacted_all(keys: Array) -> bool:
	for key in keys:
		if key not in interacted_objects:
			return false
	return true

func _physics_process(_delta: float) -> void:
	# --- MOVEMENT LOGIC ---
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * _delta
	# --- Movement & Attack Lock ---
	if not is_attacking:
		# Handle Jump Input
		if Input.is_action_just_pressed("ui_up") and is_on_floor():
			velocity.y = jump_velocity
		# 🟢 NEW: Handle Drop Down through One-Way Platforms
		if Input.is_action_just_pressed("ui_down") and is_on_floor():
			# This small nudge down forces the player off the platform's top surface.
			#// Since the platform has One Way Collision enabled, the player immediately falls through.
			global_position.y += 2.0
			velocity.y = 0 # Resetting Y velocity ensures a clean drop, not a bounce
		# Get horizontal input direction
		direction = Input.get_axis("ui_left", "ui_right")
		# Handle horizontal movement
		if direction != 0:
			velocity.x = direction * speed
			animated_sprite.flip_h = direction < 0
			
			# Mirror the Attack Hitbox 
			# We use sign(direction) to get 1 (right) or -1 (left)
			# This multiplies the base offset to move the hitbox
			attack_area.position.x = attack_offset_x * sign(direction)
			
		else:
			# Decelerate when no input is pressed
			velocity.x = move_toward(velocity.x, 0, speed)
	else:
		# When attacking, stop the player from sliding
		velocity.x = move_toward(velocity.x, 0, speed * _delta * 5)
	
	# Handle Animation State Logic
	if not is_attacking:
		if not is_on_floor():
			if velocity.y < 0:
				animated_sprite.play("jump")
			else:
				animated_sprite.play("fall")
		elif direction != 0:
			animated_sprite.play("Run")
		else:
			animated_sprite.play("Idle")
	# Move the character using physics
	move_and_slide()

# This function is called when the "attack" animation finishes playing
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "Attack":
		is_attacking = false
		# Deactivate the hitbox immediately after the animation finishes
		attack_area.monitoring = false
		# The main _physics_process loop will immediately switch to run/idle/jump animation next frame


func _on_attack_area_body_entered(body: Node) -> void:
	if not is_attacking:
		return# Only register hits during an attack
	
	if body.is_in_group("enemies"):
		body.die()# Call the enemy's die() function

func flash_red() -> void:
	animated_sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = Color(1, 1, 1)

func die() -> void:
	animated_sprite.play("Dead")
	set_physics_process(false)
	get_tree().paused = true
	if game_over_screen_scene:
		var game_over_screen_instance = game_over_screen_scene.instantiate()
		# Add the screen to the scene tree
		get_tree().root.add_child(game_over_screen_instance)
	else:
		# Fallback if the scene wasn't set in the editor
		print("GAME OVER. Missing Game Over Scene Path.")
	await animated_sprite.animation_finished
	queue_free()

# This function should only handle damage and *check* for death, 
# not handle the scene reload itself unless you are doing a soft respawn.
# We only want to take damage (1) and call die() if health hits zero.
func take_damage_and_respawn() -> void:
	# Deduct 1 health (assuming the kill zone is lethal)
	take_damage(1, Vector2.ZERO)
	
	# If the player is still alive after the damage, teleport them back.
	if current_health > 0:
		set_physics_process(false)
		is_attacking = false
		attack_area.monitoring = false
		velocity = Vector2.ZERO
		global_position = respawn_point_position
		
		# Update UI after a soft respawn/teleport back to checkpoint
		if is_instance_valid(ui) and ui.has_method("update_health"):
			ui.update_health(current_health)
			
		set_physics_process(true)
	# NOTE: If current_health <= 0, the take_damage call above already called die().
		
func win() -> void:
	# Disable player movement and input
	set_physics_process(false)
	set_process_input(false)
	# Stop all input/processing in the game world
	get_tree().paused = true
	# Instantiate and display the Win Screen
	if win_screen_scene:
		var win_screen_instance = win_screen_scene.instantiate()
		get_tree().root.add_child(win_screen_instance)
		print("Player collected win condition. Displaying Win Screen.")
	else:
		print("WIN: Missing Win Screen Scene Path in Player Inspector.")
