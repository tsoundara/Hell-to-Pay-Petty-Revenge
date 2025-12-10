class_name Boss
extends CharacterBody2D

# --- EXPORTED PROPERTIES ---
@export var max_health: int = 10
@export var walk_speed: float = 80.0
@export var chase_speed: float = 120.0
@export var attack_range: float = 60.0
@export var attack_cooldown_time: float = 1.5
@export var attack_hitbox_offset_x: float = 40.0 # Distance of the attack box from the boss center (facing right)

# --- NODE REFERENCES ---
@onready var animated_sprite: AnimatedSprite2D = $BossAnimatedSprite
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $ProgressBar

# --- STATE VARIABLES ---
var current_health: int
var player: CharacterBody2D = null
var is_chasing: bool = false
var is_attacking: bool = false
var is_dead: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- INITIALIZATION ---
func _ready() -> void:
	current_health = max_health
	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.start() # Start the timer immediately
	animated_sprite.play("Idle")
	
	# Set initial attack area position (assuming boss faces right by default)
	attack_area.position.x = attack_hitbox_offset_x
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show()

# --- PHYSICS PROCESS (Movement & AI Logic) ---
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_chasing and player:
		handle_chase_and_attack(delta)
	else:
		# Idle state when player is not detected
		animated_sprite.play("Idle")
		velocity.x = 0
	
	move_and_slide()

# --- AI LOGIC ---
func handle_chase_and_attack(delta: float) -> void:
	if not player:
		is_chasing = false
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	var direction = sign(player.global_position.x - global_position.x)
	
	# Flip sprite and attack area
	animated_sprite.flip_h = direction < 0
	attack_area.position.x = attack_hitbox_offset_x * direction
	
	if is_attacking:
		velocity.x = 0
		return # Stop all movement while attacking
		
	if distance_to_player <= attack_range:
		# Attack range reached
		velocity.x = 0
		animated_sprite.play("Idle")
		if attack_cooldown_timer.is_stopped():
			attack()
	else:
		# Chase player
		animated_sprite.play("Walk")
		velocity.x = direction * chase_speed

func attack() -> void:
	is_attacking = true
	animated_sprite.play("Attack")
	# Hitbox is active during the animation
	attack_area.monitoring = true
	
	# Check for overlapping bodies immediately when the attack starts 
	#// This prevents the "player already overlapping" bug.
	_check_initial_overlap()
	
	attack_cooldown_timer.start()
	
	# Wait for the attack animation to finish
	await animated_sprite.animation_finished
	if animated_sprite.animation == "Attack":
		is_attacking = false
		attack_area.monitoring = false
		animated_sprite.play("Idle")

# --- DAMAGE APPLICATION ---
func _check_initial_overlap() -> void:
	#// If the player is already touching the hitbox when the attack animation starts, 
	#// deal damage immediately.
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			_apply_damage(body)
			break

func _apply_damage(body: Node) -> void:
	#// Assuming the player script has a take_damage(amount, knockback_force) function
	if body.has_method("take_damage"):
		#// Deal 1 HP damage
		var knockback_direction = sign(body.global_position.x - global_position.x)
		var knockback_force = Vector2(knockback_direction * 100, -50)
		body.take_damage(1, knockback_force)

# --- BOSS STATS AND DAMAGE ---
func take_damage(amount: int, knockback_force: Vector2) -> void:
	if is_dead:
		return
		
	current_health -= amount
	health_bar.value = current_health
	flash_red()
	
	if current_health <= 0:
		die()
	else:
		#// Optional: Apply knockback on hit
		velocity = knockback_force

func flash_red() -> void:
	animated_sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = Color(1, 1, 1)

func die() -> void:
	is_dead = true
	animated_sprite.play("Dead")
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true) # Disable main body collision
	attack_area.monitoring = false
	health_bar.hide()
	
	#// Wait for death animation, then remove the boss
	await animated_sprite.animation_finished
	queue_free()


# --- SIGNAL CONNECTIONS ---

#// 1. Detection: Player enters the large Area2D
func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body as CharacterBody2D
		is_chasing = true

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player:
		is_chasing = false
		player = null

#// 2. Attack: Player enters the small attack Area2D during an active attack
func _on_attack_area_body_entered(body: Node) -> void:
	if not is_attacking:
		return 
	
	if body.is_in_group("player"):
		_apply_damage(body)
		#attack_area.monitoring = false // Prevent continuous damage during one attack frame
