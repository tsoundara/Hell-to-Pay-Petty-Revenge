extends CharacterBody2D

@export var speed: float = 50.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Starts moving right (1.0) or left (-1.0)
var direction: float = 1.0 

# Get a reference to the new AnimatedSprite2D node
@onready var animated_sprite: AnimatedSprite2D = $EnemyAnimatedSprite

func _ready():
	# Start the initial animation
	animated_sprite.play("Walk") # Or "walk", depending on your animation name
	# Ensure it starts facing the correct direction
	animated_sprite.flip_h = direction < 0


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Ensure the run animation plays when on the ground
		if animated_sprite.animation != "Walk":
			animated_sprite.play("Walk")

	# Set horizontal velocity
	velocity.x = speed * direction

	move_and_slide()
	
	# If we collided with a wall, reverse direction and flip sprite
	if is_on_wall():
		direction *= -1
		# Flip the sprite visually when changing direction
		animated_sprite.flip_h = direction < 0
