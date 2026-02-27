extends CharacterBody3D

# --- Settings ---
enum State { IDLE, CHASE, ATTACK }
var current_state = State.IDLE

@export var speed = 4.0
@export var attack_distance = 2 # Short distance for sword
@export var detection_range = 15

# --- Nodes ---
@onready var sprite = $AnimatedSprite3D
@onready var eyes = $RayCast3D
@onready var navAgent = $NavigationAgent3D
@onready var player = get_tree().get_first_node_in_group("Player")

# --- Variables ---
var inTransition = false

func _physics_process(delta):
	if not is_on_floor(): velocity.y -= 27 * delta
	# Fallback if player is missing
	if not player: return

	if !is_on_floor(): velocity.y-=20
	
	
	match current_state:
		State.IDLE:
			process_idle_state()
		State.CHASE:
			process_chase_state(delta)
		State.ATTACK:
			process_attack_state()

# --- State Logic ---

func process_idle_state():
	if inTransition: return
	
	sprite.play("Idle0")
	velocity = Vector3.ZERO # Stop movement
	
	if can_see_player():
		inTransition = true
		sprite.play("Equip")
		await sprite.animation_finished
		inTransition = false
		current_state = State.CHASE

func process_chase_state(delta):
	if inTransition: return
	
	
	navAgent.target_position = player.global_position
	
	# Check if the path is ready
	if navAgent.is_navigation_finished(): return
	
	var nextPathPos = navAgent.get_next_path_position()
	
	sprite.play("Walk")
	
	# Rotate to look at player (Y-axis only)
	var look_target = nextPathPos
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	# Move toward player
	var dir = (nextPathPos - global_position).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
	
	# Check transitions
	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_distance:
		current_state = State.ATTACK
	elif not can_see_player() and dist > detection_range:
		inTransition = true
		sprite.play_backwards("Equip")
		await sprite.animation_finished
		inTransition = false
		current_state = State.IDLE

func process_attack_state():
	# Stop movement during the swing
	velocity = Vector3.ZERO
	
	sprite.play("Attack1")
	# Wait for animation to finish before deciding what to do next
	await sprite.animation_finished
		
	# Decide: Chase again or keep attacking?
	if global_position.distance_to(player.global_position) > attack_distance:
		current_state = State.CHASE
		

# --- Helpers ---

func can_see_player() -> bool:
	var dist = global_position.distance_to(player.global_position)
	if dist > detection_range: return false
	
	# Point the RayCast eyes at the player
	eyes.look_at(player.global_position) # Look at chest/head
	eyes.force_raycast_update()
	
	if eyes.is_colliding():
		return eyes.get_collider().is_in_group("Player")
	return false
