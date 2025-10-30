extends CharacterBody2D

# Export variables for easy adjustment in the editor
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 800.0

var _velocity: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		_velocity.y += gravity * delta
	# Handle horizontal input
	var direction: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if direction:
		_velocity.x = direction * speed
		# Flip sprite based on direction (assuming $Sprite is the Sprite2D node)
		$Sprite.flip_h = direction < 0
	else:
		_velocity.x = move_toward(_velocity.x, 0, speed * delta * 5) # Apply friction
   

 # Handle jump input
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_velocity.y = jump_velocity
	
# Move the character
velocity = _velocity
move_and_slide()
