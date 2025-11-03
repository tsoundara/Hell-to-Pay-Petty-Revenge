extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0

# Get the gravity from project settings (usually 980)
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta


	# Handle Jump Input
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	# Get horizontal input direction
	var direction: float = Input.get_axis("ui_left", "ui_right")

	# Handle horizontal movement and animation
	if direction != 0:
		velocity.x = direction * speed
		# Flip the sprite to face the movement direction
		animated_sprite.flip_h = direction < 0
		if is_on_floor():
			animated_sprite.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, speed) # Decelerate when no input
		if is_on_floor():
			animated_sprite.play("Idle")

	# Handle vertical animation (jump/fall)
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")

	# Move the character
	move_and_slide()


func _on_animated_sprite_2d_animation_finished() -> void:
	
