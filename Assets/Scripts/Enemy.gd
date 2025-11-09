extends CharacterBody2D

@export var walk_speed: float = 60.0
@export var run_speed: float = 120.0
@export var patrol_distance: float = 100.0
@export var attack_cooldown: float = 1.0

@onready var animated_sprite: AnimatedSprite2D = $EnemyAnimatedSprite
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

var start_position: Vector2
var direction: int = 1
var is_chasing: bool = false
var player: Node2D = null
var is_attacking: bool = false
var can_attack: bool = true
var is_dead: bool = false

func _ready() -> void:
	start_position = global_position
	animated_sprite.play("Idle")

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
		return  # Prevent double-death calls
	is_dead = true
	
	# Flash red for feedback
	flash_red()
	# Slight delay before death animation starts
	await get_tree().create_timer(0.1).timeout
	
	# Stop movement & play death animation
	velocity = Vector2.ZERO
	animated_sprite.play("Death")
	
	# Disable collision to prevent further hits
	$CollisionShape2D.set_deferred("disabled",true)
	
	# Queue_free after animation ends
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if animated_sprite.animation == "Death":
		queue_free()

func flash_red() -> void:
	animated_sprite.modulate = Color(1, 0.2, 0.2)  # Tint red
	await get_tree().create_timer(0.1).timeout     # Flash duration
	animated_sprite.modulate = Color(1, 1, 1)      # Back to normal

func patrol(_delta: float) -> void:
	animated_sprite.play("Walk")
	velocity.x = direction * walk_speed
	move_and_slide()

	# Flip sprite visually
	animated_sprite.flip_h = direction < 0


	# Turn around at patrol boundaries
	if abs(global_position.x - start_position.x) > patrol_distance:
		direction *= -1



func chase_player(_delta: float) -> void:
	if not player:
		return

	var distance = player.global_position.x - global_position.x
	direction = sign(distance)
	animated_sprite.flip_h = direction < 0


	# If close enough, try to attack
	if abs(distance) < 40.0:
		attack()
		return

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


func _on_enemy_animated_sprite_animation_finished() -> void:
	if animated_sprite.animation.begins_with("Attack"):
		is_attacking = false
		animated_sprite.play("Idle")

func _on_attack_area_body_entered(body: Node) -> void:
	if not is_attacking:
		return
	if body.is_in_group("player"):
		# Calculate knockback direction
		var dir = sign(body.global_position.x - global_position.x)
		var knockback_force = Vector2(dir * 200, -150)
		body.take_damage(1, knockback_force)
