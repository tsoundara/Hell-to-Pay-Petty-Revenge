class_name Boss
extends CharacterBody2D

# --- EXPORTED PROPERTIES ---
@export var max_health: int = 5
@export var walk_speed: float = 80.0
@export var chase_speed: float = 120.0
@export var attack_range: float = 60.0
@export var attack_cooldown_time: float = 1.25
@export var attack_hitbox_offset_x: float = 40.0 # Distance of the attack box from the boss center (facing right)
@export var player_knockback_x: float = 500.0 # Horizontal force applied to player on hit
@export var player_knockback_y: float = -50.0 # Vertical force applied (upwards)
@export var win_screen_scene: PackedScene # Reference to the WinScreen.tscn to load on death

# --- NODE REFERENCES ---
@onready var animated_sprite: AnimatedSprite2D = $BossAnimatedSprite
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $ProgressBar

# --- STATE VARIABLES ---
var current_health: int
var player: CharacterBody2D = null
var is_chasing: bool = false
var is_attacking: bool = false
var is_dead: bool = false
var is_taking_knockback: bool = false
var time_since_last_attack: float = 999.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var attack_cooldown_value: float = 0.0


# --- INITIALIZATION ---
func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	animated_sprite.play("Idle")
	attack_area.position.x = attack_hitbox_offset_x
	attack_area.monitoring = false
	
	var sprite_frames = animated_sprite.sprite_frames
	sprite_frames.set_animation_loop("Dead", false)
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show()
	
	# Connect the detection signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Also connect the attack area signal
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	detection_area.area_entered.connect(_on_detection_area_area_entered)
	
	var shapes = detection_area.get_children()
	for child in shapes:
		if child is CollisionShape2D:
			print("DetectionArea shape: ", child.shape)
			print("DetectionArea shape disabled: ", child.disabled)
	
	print("Detection area exists: ", detection_area != null)
	print("Detection area monitoring: ", detection_area.monitoring)
	print("Detection area collision mask: ", detection_area.collision_mask)

# --- PHYSICS PROCESS ---
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	time_since_last_attack += delta
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_taking_knockback:
		move_and_slide()
		return
		
	if is_chasing and player:
		handle_chase_and_attack(delta)
	else:
		animated_sprite.play("Idle")
		velocity.x = 0
	
	move_and_slide()

# --- AI LOGIC ---
func handle_chase_and_attack(delta: float) -> void:
	if not player:
		print("CHASE - No player found, stopping chase")
		is_chasing = false
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	var direction = sign(player.global_position.x - global_position.x)
		
	animated_sprite.flip_h = direction < 0
	attack_area.position.x = attack_hitbox_offset_x * direction
	
	if is_attacking:
		velocity.x = 0
		print("CHASE - Currently attacking, not moving")
		return
		
	if distance_to_player <= attack_range:
		velocity.x = 0
		animated_sprite.play("Idle")
		if time_since_last_attack >= attack_cooldown_time:
			print("CHASE - In range and ready, starting attack")
			attack()
		else:
			print("CHASE - In range but not ready")
	else:
		print("CHASE - Moving toward player")
		animated_sprite.play("Walk")
		velocity.x = direction * chase_speed

func attack() -> void:
	print("ATTACK STARTED")
	is_attacking = true
	time_since_last_attack = 0.0
	animated_sprite.play("Attack")
	attack_area.monitoring = true
	_check_initial_overlap()
	
	# Use a timer instead of waiting for animation
	await get_tree().create_timer(1.0).timeout  # Adjust to match attack animation length
	
	print("Attack timer finished")
	if not is_dead:
		print("Resetting attack state")
		is_attacking = false
		attack_area.monitoring = false

func _check_initial_overlap() -> void:
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			_apply_damage(body)
			break

func _apply_damage(body: Node) -> void:
	if body.has_method("take_damage"):
		var knockback_direction = sign(body.global_position.x - global_position.x)
		var knockback_force = Vector2(knockback_direction * player_knockback_x, player_knockback_y)
		body.take_damage(2, knockback_force)
	attack_area.monitoring = false

# --- STATS AND DAMAGE ---
func take_damage(amount: int, knockback_force: Vector2) -> void:
	if is_dead:
		return
		
	current_health -= amount
	health_bar.value = current_health
	flash_red()
	
	if current_health <= 0:
		die()
	else:
		velocity = knockback_force
		is_taking_knockback = true
		await get_tree().create_timer(0.2).timeout
		is_taking_knockback = false

func flash_red() -> void:
	animated_sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = Color(1, 1, 1)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	flash_red()
	await get_tree().create_timer(0.1).timeout
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	attack_area.monitoring = false
	health_bar.hide()
	
	animated_sprite.play("Dead")
	await animated_sprite.animation_finished
	
	# Stop on last frame
	animated_sprite.stop()
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("Dead") - 1
	
	if win_screen_scene:
		get_tree().paused = true
		
		var win_screen_instance = win_screen_scene.instantiate()
		get_tree().root.add_child(win_screen_instance)
		print("Boss defeated. Displaying Win Screen.")
	else:
		print("ERROR: Win Screen Scene not set in Boss Inspector!")
		


# --- SIGNAL CONNECTIONS ---
func _on_detection_area_body_entered(body: Node) -> void:
	print("DETECTION - Body entered: ", body.name, " | is_player: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		player = body as CharacterBody2D
		is_chasing = true
		print("DETECTION - Started chasing player")

func _on_detection_area_body_exited(body: Node) -> void:
	print("DETECTION - Body exited: ", body.name)
	if body == player:
		is_chasing = false
		player = null
		print("DETECTION - Stopped chasing player")

func _on_attack_area_body_entered(body: Node) -> void:
	print("Body entered attack area. is_attacking: ", is_attacking, " monitoring: ", attack_area.monitoring)
	if not is_attacking:
		print("Blocked - not attacking")
		return
	if not attack_area.monitoring:
		print("Blocked - monitoring off")
		return
	
	if body.is_in_group("player"):
		print("DAMAGE APPLIED")
		_apply_damage(body)

func _on_detection_area_area_entered(area: Area2D) -> void:
	
	print("DETECTION - Area entered: ", area.name, " with owner: ", area.owner.name if area.owner else "no owner")
