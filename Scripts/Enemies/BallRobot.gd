extends CharacterBody3D

# --- Settings ---
@export var speed: float = 8.0          # High speed for testing the flank velocity
@export var flank_distance: float = 4.5 # How many meters behind the player it aims for

# --- Nodes ---
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var visual_mesh: MeshInstance3D = $BallMesh # Replace with your ball's visual node name
@onready var player = get_tree().get_first_node_in_group("Player")

var look_target_desired
var look_target

func _ready() -> void:
	look_target_desired = $RayCast3D/Rayend.global_position
	look_target = look_target_desired

func _physics_process(delta: float) -> void:
	# Apply basic gravity if it's airborne
	if not is_on_floor():
		velocity.y -= 15.0 * delta
		
	# Fallback if player hasn't spawned yet
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		return

	# 1. CALCULATE THE POSITION BEHIND THE PLAYER
	# -player.global_transform.basis.z gives the direction the player is facing.
	var player_forward = -player.global_transform.basis.z.normalized()
	var target_behind_player = player.global_position - (player_forward * flank_distance)
	
	# Update the Navigation Agent's target
	nav_agent.target_position = target_behind_player
	
	# 2. MOVEMENT LOGIC
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var move_direction = (next_path_pos - global_position).normalized()
		
		# Smooth out horizontal velocity transitions
		velocity.x = lerp(velocity.x, move_direction.x * speed, delta * 8.0)
		velocity.z = lerp(velocity.z, move_direction.z * speed, delta * 8.0)
		
		# Make the ball look at the player at all times while it runs behind them
		look_target = player.global_position
		look_target.y = global_position.y # Prevent pitching up/down
		look_at(look_target, Vector3.UP)
	else:
		# Slow down smoothly if it somehow perfectly reaches the spot
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)

	move_and_slide()
	
	# 3. VISUAL BALL ROLL (Optional)
	# Procedurally rotates the visual mesh node based on movement velocity
	if velocity.length() > 0.2 and visual_mesh:
		var roll_axis = Vector3.UP.cross(velocity.normalized())
		visual_mesh.rotate(roll_axis, (velocity.length() / speed) * delta * 12.0)
