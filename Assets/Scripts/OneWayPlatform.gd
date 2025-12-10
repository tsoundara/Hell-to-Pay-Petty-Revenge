extends StaticBody2D

# Use an Area2D to detect when the player is standing on the platform
@onready var detection_area: Area2D = $DetectionArea 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D 

var player_on_platform = false

func _ready():
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _on_detection_area_body_entered(body: Node2D):
	if body is Player:
		player_on_platform = true

func _on_detection_area_body_exited(body: Node2D):
	if body is Player:
		player_on_platform = false

#// The Player calls this function when they press 'down'
func enable_pass_through():
	if player_on_platform:
		collision_shape.disabled = true
		await get_tree().physics_frame
		collision_shape.disabled = false
