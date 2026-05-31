extends CharacterBody3D

# --- Settings ---
enum State { IDLE, CHASE, ATTACK }
var current_state = State.IDLE

@export var speed: float = 3.5
@export var attack_start_distance: float = 8.0 # when start shooting
@export var attack_stop_distance: float = 12.0 # when stop shooting
@export var kick_distance: float = 2.0
@export var detection_range: float = 25.0
@export var enemy_gun_damage: float = 30.0
@export var enemy_kick_damage: float = 50.0
@export var enemy_health: float = 100.0

# --- Nodes ---
@onready var chargeBall = $Skeleton3D/ArmR/chargeBall
@onready var chargeBalls = $Skeleton3D/ArmR/chargeBalls
@onready var bullet = $Skeleton3D/ArmR/Bullet
@onready var animation = $AnimationPlayer
@onready var skeleton = $Skeleton3D
@onready var aimHand = $aimHand
@onready var eyes = $RayCast3D
@onready var bulletRay = $Skeleton3D/ArmR/BulletRay
@onready var bulletRayEnd = $Skeleton3D/ArmR/BulletRayEnd
@onready var kickRay = $Skeleton3D/LegL/kick
@onready var navAgent = $NavigationAgent3D
@onready var player = get_tree().get_first_node_in_group("Player")

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
var aim_target = 0.0
var dist = 9999.0


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
	if !is_on_floor():
		velocity.y -= 15 * delta
	# Fallback if player is missing
	if not player:
		if get_tree().get_first_node_in_group("Player"):
			player = get_tree().get_first_node_in_group("Player")
		return
	
	#if is_on_wall() and is_on_floor():
	#	var canJump: bool = true
	#	for ray in $Feet.get_children():
	#		if ray.is_colliding(): canJump = false
	#	if canJump:
	#		var walk_dir = (look_target - global_position).normalized()
	#		var object_dir = -get_wall_normal()
	#		var angle = walk_dir.signed_angle_to(object_dir, Vector3.UP)
	#		print(rad_to_deg(angle))
	#		if abs(angle) < deg_to_rad(55.0): velocity.y = 4.0
	
	dist = global_position.distance_to(player.global_position)
	
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
		if animation.is_playing():
			await animation.animation_finished
		animation.play("undraw")
		return
	
	if walking:
		animation.play_section("walk", 1.7, 1.8, -1, walkAnimScale)
		walking = false
	
	if !knocked:
		velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	
	if (can_see_player() or damagedByPlayer) and !player.dead:
		inTransition = true
		if !awake:
			awake = true
			animation.play("alert")
			await get_tree().create_timer(0.4).timeout
		animation.play("draw")
		await get_tree().create_timer(0.35).timeout
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
	
	if !animation.is_playing():
		if !walking:
			animation.play_section("walk", 0.0, 1.7, -1, walkAnimScale)
			walking = true
		else:
			animation.play_section("walk", 0.1, 1.7, -1, walkAnimScale)
	
	# Rotate to look at player (Y-axis only)
	look_target_desired = nextPathPos
	look_target_desired.y = global_position.y
	look_target = lerp(look_target, look_target_desired, delta * 3.5)
	look_at(look_target, Vector3.UP)
	
	# Move toward player
	#var dir = (nextPathPos - global_position).normalized()
	var dir = (look_target - global_position).normalized()
	if !knocked:
		velocity.x = lerp(velocity.x, dir.x * speed, delta * 5.0)
		velocity.z = lerp(velocity.z, dir.z * speed, delta * 5.0)
	
	# Check transitions
	dist = global_position.distance_to(player.global_position)
	if dist <= attack_start_distance and can_see_player():
		current_state = State.ATTACK
	elif !can_see_player() and dist > detection_range and !damagedByPlayer:
		inTransition = true
		animation.play("undraw")
		await get_tree().create_timer(0.35).timeout
		inTransition = false
		current_state = State.IDLE

func process_attack_state(delta):
	if player.dead:
		current_state = State.IDLE
		return
	
	# Stop movement during shooting
	if walking:
		animation.play_section("walk", 1.7, 1.8, -1, walkAnimScale)
		walking = false
	
	if !knocked:
		velocity.x = lerp(velocity.x, 0.0, delta * 5.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 5.0)
	
	dist = global_position.distance_to(player.global_position)
	if dist <= kick_distance:
		turn_mod = 4.0
	else:
		turn_mod = 0.8
	
	# Look at player
	look_target_desired = player.global_position
	look_target_desired.y = global_position.y
	look_target = lerp(look_target, look_target_desired, delta * 3.5 * turn_mod)
	look_at(look_target, Vector3.UP)
	aim(delta)
	
	# Decide: Player forever-napping or keep attaking?
	if !isInAttack:
		isInAttack = true
		if dist <= kick_distance:
			kick()
		else:
			shoot()
	
	
	# Decide: Chase again or keep attacking?
	if player.dead == true:
		current_state = State.IDLE
	
	if global_position.distance_to(player.global_position) > attack_stop_distance or !can_see_player():
		current_state = State.CHASE


func process_dead_state(): # gotta make death anim   Zzzzz
	player.enemy_killed()
	queue_free()

func aim(delta):
	var hand_bone = skeleton.find_bone("Hand.R")
	aimHand.look_at(player.global_position, Vector3.UP, true)
	aim_target = lerp_angle(aim_target, aimHand.rotation.x, delta * 3.0)
	
	var new_rotation = Quaternion.from_euler(Vector3(aim_target + PI/2, deg_to_rad(90), 0))
	skeleton.set_bone_pose_rotation(hand_bone, new_rotation)

func kick():
	if animation.is_playing(): pass
	animation.play("kick")
	await get_tree().create_timer(0.21).timeout
	if kickRay.is_colliding():
		if kickRay.get_collider().is_in_group("Player"):
			kickRay.get_collider().damage_taken(enemy_kick_damage, false)
			var dir = player.global_position - global_position
			kickRay.get_collider().knockBack(dir + Vector3(0.0,0.05 if player.is_on_floor() else 0.0,0.0), 7.0, false, 0.3)
	await get_tree().create_timer(0.3).timeout
	isInAttack = false

func shoot():
	chargeBall.restart()
	chargeBall.emitting = true
	chargeBalls.restart()
	chargeBalls.emitting = true
	await get_tree().create_timer(1.25).timeout
	if dist <= kick_distance: 
		kick()
		return
	if bulletRay.is_colliding():
		bullet.lifetime = bulletRay.global_position.distance_to(bulletRay.get_collision_point()) / bulletRay.global_position.distance_to(bulletRayEnd.global_position)
	else: bullet.lifetime = 0.5
	bullet.emitting = true
	if bulletRay.is_colliding():
		if bulletRay.get_collider().is_in_group("Player"):
			bulletRay.get_collider().damage_taken(enemy_gun_damage, false)
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
