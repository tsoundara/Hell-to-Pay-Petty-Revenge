extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_health: int = 5
var current_health: int
@export var respawn_point_position: Vector2 = Vector2.ZERO # Default to (0, 0)
@export var game_over_screen_scene: PackedScene
@export var win_screen_scene: PackedScene


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

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int, knockback_force: Vector2) -> void:
	current_health -= amount
	# Apply knockback
	velocity = knockback_force
	# Optional: flash red or play hurt animation
	flash_red()
	if current_health <= 0:
		die()

func _physics_process(_delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * _delta
	# --- Movement & Attack Lock ---
	if not is_attacking:
		# Handle Jump Input
		if Input.is_action_just_pressed("ui_up") and is_on_floor():
			velocity.y = jump_velocity
		# Get horizontal input direction
		direction = Input.get_axis("ui_left", "ui_right")
		# Handle horizontal movement
		if direction != 0:
			velocity.x = direction * speed
			animated_sprite.flip_h = direction < 0
		else:
			# Decelerate when no input is pressed
			velocity.x = move_toward(velocity.x, 0, speed)
	else:
		# When attacking, stop the player from sliding
		# This makes the attack feel weightier/more grounded.
		velocity.x = move_toward(velocity.x, 0, speed * _delta * 5)
	
	# Handle Animation State Logic (Remains the same as your original code)
	if not is_attacking:
		if not is_on_floor():
			# Vertical animations take priority over run/idle
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
		return  # Only register hits during an attack
	
	if body.is_in_group("enemies"):
		body.die()  # Call the enemy's die() function

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

func take_damage_and_respawn() -> void:
	# Stop processing physics during the respawn
	set_physics_process(false)
	# 1. Deduct life/health if you are using a life count system
	# current_health -= 1 # Example
	# 2. Reset Player State (Crucial for a clean respawn)
	current_health = max_health # Restore health
	is_attacking = false
	attack_area.monitoring = false
	velocity = Vector2.ZERO
	# 3. Teleport to Respawn Point
	global_position = respawn_point_position
	# Optional: Brief invulnerability flash or fade-in effect here
	# 4. Resume processing physics
	set_physics_process(true)
	# 5. Handle Game Over if necessary
	if current_health <= 0:
		# NOTE: You'll likely want a separate Game Manager to handle game over screens
		print("GAME OVER")
		
func win() -> void:
	# 1. Disable player movement and input
	set_physics_process(false)
	set_process_input(false)
	# 2. Stop all input/processing in the game world
	get_tree().paused = true
	# 3. Instantiate and display the Win Screen
	if win_screen_scene:
		var win_screen_instance = win_screen_scene.instantiate()
		get_tree().root.add_child(win_screen_instance)
		print("Player collected win condition. Displaying Win Screen.")
	else:
		print("WIN: Missing Win Screen Scene Path in Player Inspector.")
