extends CharacterBody2D

@export var walk_speed: float = 60.0
@export var run_speed: float = 120.0
@export var patrol_distance: float = 100.0
@export var attack_cooldown: float = 1.0
@export var base_attack_offset_x: float = 15.0

@onready var animated_sprite: AnimatedSprite2D = $EnemyAnimatedSprite
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var ground_check_ray: RayCast2D = $GroundCheckRayCast
@onready var wall_check_ray: RayCast2D = $WallCheckRayCast

var start_position: Vector2
var direction: int = 1
var is_chasing: bool = false
var player: Node2D = null
var is_attacking: bool = false
var can_attack: bool = true
var is_dead: bool = false
var is_returning_home: bool = false

func _ready() -> void:
	start_position = global_position
	animated_sprite.play("Idle")
	# Ensure attack area is initially positioned correctly
	attack_area.position.x = base_attack_offset_x * direction

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_attacking:
		return  # Don’t move during attacks

	if is_chasing and player:
		chase_player(delta)
	else:
		patrol(delta)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	flash_red()
	await get_tree().create_timer(0.1).timeout
	velocity = Vector2.ZERO
	animated_sprite.play("Death")
	$CollisionShape2D.set_deferred("disabled", true)
	# ✅ Add points to player
	if player and player.has_method("add_score"):
		player.add_score(100)
	await animated_sprite.animation_finished
	queue_free()

func flash_red() -> void:
	animated_sprite.modulate = Color(1, 0.2, 0.2)  # Tint red
	await get_tree().create_timer(0.1).timeout     # Flash duration
	animated_sprite.modulate = Color(1, 1, 1)      # Back to normal


func patrol(_delta: float) -> void:
	animated_sprite.play("Walk")
	# Determine the speed based on state
	var current_speed = walk_speed
	if is_returning_home:
		# Run back home fast, ignore patrol boundaries
		current_speed = run_speed
		# Check if enemy is close enough to home to start regular patrol
		if abs(global_position.x - start_position.x) < 5.0: # Check within 5 units
			is_returning_home = false
			# Reset direction for standard patrol (e.g., face right)
			direction = 1
	# --- Movement ---
	velocity.x = direction * current_speed
	move_and_slide()
	
	# Flip sprite visually
	animated_sprite.flip_h = direction < 0
	# 🚨 FIX: Flip the Attack Area position 🚨
	attack_area.position.x = base_attack_offset_x * direction
	
	# Patrol boundary check only when NOT returning home
	if not is_returning_home:
		if abs(global_position.x - start_position.x) > patrol_distance:
			direction *= -1


func chase_player(_delta: float) -> void:
	if not player:
		return
	var distance = player.global_position.x - global_position.x
	direction = sign(distance)
	animated_sprite.flip_h = direction < 0
	# 🚨 FIX: Flip the Attack Area position 🚨
	attack_area.position.x = base_attack_offset_x * direction
	
	var ray_scale = direction
	ground_check_ray.scale.x = ray_scale
	wall_check_ray.scale.x = ray_scale
	if not ground_check_ray.is_colliding():
		animated_sprite.play("Idle")
		velocity.x = 0
		move_and_slide()
		return # Stop if a cliff is detected
	# If close enough, decide whether to attack or wait
	if abs(distance) < 40.0:
		if can_attack and not is_attacking:
			# Start attack immediately
			attack()
		else:
			animated_sprite.play("Idle")
			velocity.x = 0
			move_and_slide()
		return # Prevents running while in attack range/wait state
	# Otherwise, run toward player
	animated_sprite.play("Run")
	velocity.x = direction * run_speed
	move_and_slide()


func attack() -> void:
	if not can_attack or is_attacking:
		return
	is_attacking = true
	can_attack = false
	velocity.x = 0
	# Pick a random attack animation
	var attack_anim = "Attack1" if randi() % 2 == 0 else "Attack2"
	animated_sprite.play(attack_anim)
	# Re-enable attack after cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_chasing = true
		player = body

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player:
		is_chasing = false
		player = null
		# Set the state flag
		is_returning_home = true
		# Stabilize direction: Face towards home
		var distance_to_start = start_position.x - global_position.x
		direction = sign(distance_to_start)
		animated_sprite.flip_h = direction < 0
		# 🚨 FIX: Update Attack Area when exiting chase 🚨
		attack_area.position.x = base_attack_offset_x * direction
		velocity.x = 0


func _on_enemy_animated_sprite_animation_finished() -> void:
	if animated_sprite.animation.begins_with("Attack"):
		is_attacking = false
	elif animated_sprite.animation == "Dead":
		queue_free()

func _on_attack_area_body_entered(body: Node) -> void:
	if not is_attacking:
		return
	if body.is_in_group("player"):
		# Calculate knockback direction
		var dir = sign(body.global_position.x - global_position.x)
		var knockback_force = Vector2(dir * 200, -150)
		body.take_damage(1, knockback_force)
