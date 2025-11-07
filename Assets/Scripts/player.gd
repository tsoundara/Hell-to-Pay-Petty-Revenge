extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

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


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump Input
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	# Get horizontal input direction
	direction = Input.get_axis("ui_left", "ui_right")

	# Handle horizontal movement
	if direction != 0:
		velocity.x = direction * speed
		# Flip the sprite visually based on movement direction
		animated_sprite.flip_h = direction < 0
	else:
		# Decelerate when no input is pressed
		velocity.x = move_toward(velocity.x, 0, speed)

	# Handle Animation State Logic
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
