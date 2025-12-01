extends StaticBody2D
#// You would attach this script to your one-way platform node.

# Use an Area2D to detect when the player is standing on the platform
@onready var detection_area: Area2D = $DetectionArea 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D 

var player_on_platform = false

func _ready():
	# Connect the Area2D signals in the editor or here
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	#// Ensure the detection area is large enough to encompass the player
	#// while they are standing on the platform.

func _on_detection_area_body_entered(body: Node2D):
	if body is Player:
		player_on_platform = true

func _on_detection_area_body_exited(body: Node2D):
	if body is Player:
		player_on_platform = false

#// The Player calls this function when they press 'down'
func enable_pass_through():
	if player_on_platform:
		#// Temporarily disable the collision shape
		collision_shape.disabled = true
		#// Re-enable the collision shape after a small delay (1 physics frame)
		#// This brief disable allows the player to fall through before re-enabling 
		#// it for the next player attempting to jump up or land on it.
		await get_tree().physics_frame
		collision_shape.disabled = false
