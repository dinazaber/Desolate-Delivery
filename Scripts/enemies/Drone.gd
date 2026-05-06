extends CharacterBody3D

# --- Settings ---
enum State { IDLE, CHASE, ATTACK }
var current_state = State.IDLE

@export var speed: float = 6.0
@export var attack_start_distance: float = 6.0 # when start shooting
@export var attack_stop_distance: float = 10.0 # when stop shooting
@export var detection_range: float = 25.0
@export var enemy_gun_damage: float = 15.0
@export var enemy_health: float = 50.0

# --- Nodes ---
@onready var animation = $AnimationPlayer
@onready var skeleton = $Skeleton3D
@onready var eyes = $RayCast3D
@onready var navAgent = $NavigationAgent3D
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("Player")

# --- Variables ---
var inTransition: bool = false
var isInAttack: bool = false
var damagedByPlayer: bool = false
var awake: bool = false
var walking: bool = false
var dead: bool = false
var knocked: bool = false
var walkAnimScale = 0.5 * speed
var turn_mod = 1.0
var look_target_desired
var look_target
var turn_rate = 0.0
var aim_target = 0.0
var dist = 9999.0
var xz_dist = 9999.0

# --- Constants ---
const DESIRED_ALTI = 3.5 # desired altitude difference (drone - player)

func save():
	var data = {
		"level_scene": get_tree().current_scene.scene_file_path,
		"filename": get_scene_file_path(),
		"parent": get_parent().get_path(),
		"transform": global_transform,
		"enemy_health": enemy_health,
		"dead": dead,
		"current_state": current_state
	}
	return data

func _ready() -> void:
	look_target_desired = $RayCast3D/Rayend.global_position
	look_target = look_target_desired

func _physics_process(delta):
	# Fallback if player is missing
	if not player:
		if get_tree().get_first_node_in_group("Player"):
			player = get_tree().get_first_node_in_group("Player")
		return
	
	# hight and wobble
	if can_see_player() or damagedByPlayer:
		var alti_diff_mod = clamp((DESIRED_ALTI - (global_position.y - player.global_position.y)) / DESIRED_ALTI, -0.5, 1.0)
		alti_diff_mod = sign(alti_diff_mod) * sqrt(abs(alti_diff_mod))
		if !(-3.0 <= velocity.y and velocity.y <= 3.0): alti_diff_mod = -3.0 * sign(velocity.y)*abs(alti_diff_mod)
		velocity.y += (15.0 * alti_diff_mod) * delta
	else: velocity.y = 0.0
	
	# movement tilt
	skeleton.rotation_degrees.z = clamp(5.0 * Vector3(velocity.x, 0.0, velocity.z).length(), -20.0, 20.0)
	
	# thrust particles - if you want to stuff this mess into a shader, you're welcome
	var vel_state = 1.0 if velocity.y > 0 else 2/(2-velocity.y)
	$Skeleton3D/ThrusterLB/Thrust.speed_scale = vel_state
	$Skeleton3D/ThrusterRB/Thrust.speed_scale = vel_state
	$Skeleton3D/ThrusterRF/Thrust.speed_scale = vel_state
	$Skeleton3D/ThrusterLF/Thrust.speed_scale = vel_state
	
	# thruster angle
	var look_dir: Vector3 = look_target - global_position
	var look_dir_desired: Vector3 = look_target_desired - global_position
	var turn_angle = clamp(look_dir_desired.signed_angle_to(look_dir, Vector3.UP), deg_to_rad(-20.0), deg_to_rad(20.0))
	for thruster_bone_index in range(1, 5): # NOTE: will self destruct if bone order is changed (fixable via .find_bone but im lazy)
		var thruster_rot = skeleton.get_bone_pose_rotation(thruster_bone_index).get_euler()
		thruster_rot.x = turn_angle
		thruster_rot = Quaternion.from_euler(thruster_rot)
		skeleton.set_bone_pose_rotation(thruster_bone_index, thruster_rot)
	
	dist = global_position.distance_to(player.global_position)
	xz_dist = sqrt((global_position.x - player.global_position.x)**2 + (global_position.z - player.global_position.z)**2)
	
	if !dead:
		match current_state:
			State.IDLE:
				process_idle_state(delta)
			State.CHASE:
				process_chase_state(delta)
			State.ATTACK:
				process_attack_state(delta)
	else:
		process_dead_state()
	
	move_and_slide()

# --- State Logic ---

func process_idle_state(delta):
	if inTransition: return
	
	if player.dead and awake:
		awake = false
		#if animation.is_playing():
		#	await animation.animation_finished
		#animation.play("undraw")
		return
	
	if walking:
		#animation.play_section("walk", 1.7, 1.8, -1, walkAnimScale)
		walking = false
	
	if !knocked:
		velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	
	if (can_see_player() or damagedByPlayer) and !player.dead:
		inTransition = true
		if !awake:
			awake = true
			#animation.play("alert")
			#await get_tree().create_timer(0.4).timeout
		#animation.play("draw")
		#await get_tree().create_timer(0.35).timeout
		inTransition = false
		current_state = State.CHASE

func process_chase_state(delta):
	if inTransition: return
	
	if player.dead:
		current_state = State.IDLE
		return
	
	navAgent.target_position = player.global_position
	
	# Check if the path is ready
	if navAgent.is_navigation_finished(): return
	
	var nextPathPos = navAgent.get_next_path_position()
	
	#if !animation.is_playing():
	#	if !walking:
	#		animation.play_section("walk", 0.0, 1.7, -1, walkAnimScale)
	#		walking = true
	#	else:
	#		animation.play_section("walk", 0.1, 1.7, -1, walkAnimScale)
	
	# Rotate to look at player (Y-axis only)
	look_target_desired = nextPathPos
	if can_see_player():
		look_target_desired = player.global_position
	look_target_desired.y = global_position.y
	look_target = lerp(look_target, look_target_desired, delta * 3.5)
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	# Move toward player
	#var dir = (nextPathPos - global_position).normalized()
	var dir = (look_target - global_position).normalized()
	if !knocked:
		velocity.x = lerp(velocity.x, dir.x * speed, delta * 5.0)
		velocity.z = lerp(velocity.z, dir.z * speed, delta * 5.0)
	
	# Check transitions
	if xz_dist <= attack_start_distance:
		current_state = State.ATTACK
	elif !can_see_player() and dist > detection_range and !damagedByPlayer:
		inTransition = true
		#animation.play("undraw")
		#await get_tree().create_timer(0.35).timeout
		inTransition = false
		current_state = State.IDLE

func process_attack_state(delta):
	if player.dead:
		current_state = State.IDLE
		return
	
	# Stop movement during shooting
	if walking:
		#animation.play_section("walk", 1.7, 1.8, -1, walkAnimScale)
		walking = false
	
	if !knocked:
		velocity.x = lerp(velocity.x, 0.0, delta * 5.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 5.0)
	
	#if dist <= kick_distance:
	#	turn_mod = 4.0
	#else:
	#	turn_mod = 0.8
	
	# Look at player
	look_target_desired = player.global_position
	look_target_desired.y = global_position.y
	look_target = lerp(look_target, look_target_desired, delta * 3.5 * turn_mod)
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	aim(delta)
	
	# Decide: Player forever-napping or keep attaking?
	if !isInAttack:
		isInAttack = true
		#if dist <= kick_distance:
		#	kick()
		#else:
		#	shoot()
	
	
	# Decide: Chase again or keep attacking?
	if player.dead == true:
		current_state = State.IDLE
	
	if xz_dist > attack_stop_distance:
		current_state = State.CHASE


func process_dead_state(): # gotta make death anim   Zzzzz
	player.enemy_killed()
	queue_free()

func aim(_delta):
	pass
	#var hand_bone = skeleton.find_bone("Hand.R")
	#aimHand.look_at(player.global_position, Vector3.UP, true)
	#aim_target = lerp_angle(aim_target, aimHand.rotation.x, delta * 3.0)
	
	#var new_rotation = Quaternion.from_euler(Vector3(aim_target + PI/2, deg_to_rad(90), 0))
	#skeleton.set_bone_pose_rotation(hand_bone, new_rotation)

func shoot():
	#if eyes.is_colliding():
	#	bullet.lifetime = eyes.global_position.distance_to(eyes.get_collision_point()) / eyes.global_position.distance_to(bulletRayEnd.global_position)
	#else: bullet.lifetime = 0.5
	#bullet.emitting = true
	if eyes.is_colliding():
		if eyes.get_collider().is_in_group("Player"):
			eyes.get_collider().damage_taken(enemy_gun_damage, false)
	await get_tree().create_timer(1.0).timeout
	isInAttack = false

func damage_taken(recieved_damage, isPlayer):
	if isPlayer: damagedByPlayer = true
	enemy_health -= recieved_damage
	checkLifeLine()

func knockBack(direction, force, _slowOnGround, time):
	knocked = true
	velocity += direction * force
	await get_tree().create_timer(time).timeout
	knocked = false

func checkLifeLine():
	if enemy_health <= 0 and dead == false:
		dead = true


# --- Helpers ---

func can_see_player() -> bool:
	if dist > detection_range: return false
	
	# Point the RayCast eyes at the player
	eyes.look_at(player.global_position) # Look at chest/head
	eyes.force_raycast_update()
	
	if eyes.is_colliding():
		return eyes.get_collider().is_in_group("Player")
	return false
