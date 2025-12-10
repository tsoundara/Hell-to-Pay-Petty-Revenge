extends Area2D

# --- Exported Variables (Tweak in the Inspector) ---
@export var speed: float = 40.0            # Horizontal walking speed
@export var patrol_duration: float = 3.0   # Max time to walk before idling
@export var idle_min_time: float = 2.0     # Minimum time to stand still
@export var idle_max_time: float = 5.0     # Maximum time to stand still
@export var patrol_distance: float = 100.0

# --- State Constants ---
const STATE_IDLE = 0
const STATE_PATROL = 1

# --- Internal Variables ---
var start_position: Vector2
var direction: int = 1 # 1 for right, -1 for left
var current_state: int = STATE_PATROL

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_timer: Timer = $StateTimer # <-- REQUIRED: Must re-add Timer node!

func _ready() -> void:
	start_position = global_position
	
	# Connect the timer signal to the state transition function
	state_timer.timeout.connect(_on_state_timer_timeout)
	
	# Start in the patrol state
	_change_state(STATE_PATROL)

func _physics_process(delta: float) -> void:
	match current_state:
		STATE_PATROL:
			_state_patrol(delta)
		STATE_IDLE:
			_state_idle(delta)

# ----------------------------------------------------
# --- State Management and Transitions ---
# ----------------------------------------------------

func _change_state(new_state: int) -> void:
	current_state = new_state
	
	match current_state:
		STATE_PATROL:
			animated_sprite.play("Walk")
			# Set patrol duration and start the timer
			state_timer.start(patrol_duration)
		STATE_IDLE:
			animated_sprite.play("Idle")
			# Set a random idle duration and start the timer
			var idle_time = randf_range(idle_min_time, idle_max_time)
			state_timer.start(idle_time)

			if randi() % 2 == 0:
				_turn_around()
			
func _on_state_timer_timeout() -> void:
	# Logic to switch to the *other* state when the timer runs out
	if current_state == STATE_PATROL:
		_change_state(STATE_IDLE)
	elif current_state == STATE_IDLE:
		# After idling, switch back to patrol
		_change_state(STATE_PATROL)

# ----------------------------------------------------
# --- State Logic Functions ---
# ----------------------------------------------------

func _state_patrol(delta: float) -> void:
	# 1. Apply Movement
	global_position.x += direction * speed * delta

	# 2. Update Visuals
	animated_sprite.flip_h = direction < 0

	# 3. Check Boundary and Turn
	# If the NPC has moved too far from its starting position, turn around.
	if abs(global_position.x - start_position.x) >= patrol_distance:
		_turn_around()
		# Reset the timer so it doesn't immediately switch to idle after turning
		state_timer.start(patrol_duration)


func _state_idle(_delta: float) -> void:
	# Do nothing while idling. The timer handles the transition.
	pass

# --- Helper Function ---

func _turn_around() -> void:
	direction *= -1
