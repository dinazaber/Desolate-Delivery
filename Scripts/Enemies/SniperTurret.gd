extends Node3D

# --- Settings ---
enum State { IDLE, AIM, ATTACK, CAPTURED}
var current_state = State.IDLE

@export var detection_range = 50
@export var enemy_damage = 50
@export var enemy_health = 100

# --- Nodes ---
@onready var eyes = $RayCast3D
@onready var gunRay = $GunPivot/GunMesh/GunRay
@onready var captured_timer: Timer = $CapturedTimer
@onready var player = get_tree().get_first_node_in_group("Player")

# --- Body Parts ---
@onready var mount = $MountMesh
@onready var gun = $GunPivot

# --- Load ---
var damage_number = load("res://Scenes/UI/DamageNumber.tscn")
var damage_number_instance

# --- Variables ---
var inTransition: bool = false
var isInAttack: bool = false
var isCaptured: bool = false
var damagedByPlayer: bool = false
var dead: bool = false
var timerFlag: bool = false
var look_target

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
	look_target = player.global_position


func _physics_process(delta: float) -> void:
	# Fallback if player is missing
	if not player:
		if get_tree().get_first_node_in_group("Player"):
			player = get_tree().get_first_node_in_group("Player")
		return
	
	if !dead:
		match current_state:
			State.IDLE:
				process_idle_state()
			State.AIM:
				process_aim_state(delta)
			State.CAPTURED:
				process_captured_state(delta)
			State.ATTACK:
				process_attack_state()
	else:
		process_dead_state()


func process_idle_state():
	if (can_see_player() or damagedByPlayer == true) and !player.dead and !isCaptured and !isInAttack:
		current_state = State.AIM

func process_aim_state(delta):
	var angle = follow(player.global_position, 1.0, delta)
	if !timerFlag and abs(angle) <= deg_to_rad(40.0):
		timerFlag = true
		$Timer.start()
		$GunPivot/Charge.restart()
		$GunPivot/Charge.emitting = true

func process_captured_state(delta):
	$GunPivot/CapturedCharge.amount_ratio = (captured_timer.wait_time - captured_timer.time_left) / captured_timer.wait_time
	
	var target: Vector3 = player.playerRayEnd.global_position
	if player.playerRay.is_colliding(): target = player.playerRay.get_collision_point()
	
	follow(target, 2.5, delta)

func process_attack_state():
	if isInAttack: return
	isInAttack = true
	
	$GunPivot/Beam.emitting = true
	$GunPivot/Beamies.emitting = true
	if gunRay.is_colliding():
		if gunRay.get_collider().has_method("damage_taken"):
			gunRay.get_collider().damage_taken(enemy_damage, isCaptured, "bullet", gunRay.get_collision_point())
	await get_tree().create_timer(1.5).timeout
	current_state = State.IDLE if !isCaptured else State.CAPTURED
	isInAttack = false

func process_dead_state():
	player.enemy_killed()
	queue_free()


func follow(target, speed_scale, delta) -> float:
	var look_vec: Vector3 = ($GunPivot/CollEnv3SnapPos.global_position - $GunPivot.global_position).normalized()
	var target_vec: Vector3 = (target - $GunPivot.global_position).normalized()
	var angle: float = acos(look_vec.dot(target_vec))
	var rot: float = (deg_to_rad(30.0) * speed_scale * delta) if angle > deg_to_rad(30.0) * delta else angle
	var look_target_norm: Vector3 = look_vec.cross(target_vec).normalized()
	var axis: Vector3 = look_target_norm if abs(angle) < deg_to_rad(40.0) else Vector3.UP * sign(look_target_norm.y)
	
	gun.rotate(axis, rot)
	gun.rotation.x = clamp(gun.rotation.x, deg_to_rad(-20.0), deg_to_rad(20.0))
	gun.rotation.z = 0.0
	mount.rotation.y = gun.rotation.y
	
	$CollisionEnv3.global_transform = $GunPivot/CollEnv3SnapPos.global_transform
	
	return angle

func damage_taken(recieved_damage, isPlayer, type, pos):
	if type == "melee" and !isCaptured:
		recieved_damage = 0.0
		enemy_damage *= 2
		isCaptured = true
		current_state = State.CAPTURED
		$GunPivot/CapturedCharge.emitting = true
		$GunPivot/Captured.emitting = true
		captured_timer.start()
		$Timer.stop()
	
	if isPlayer: damagedByPlayer = true
	enemy_health -= recieved_damage
	
	if recieved_damage > 0:
		handle_damage_number(recieved_damage, pos)
		checkLifeLine()

func handle_damage_number(dmg, pos):
	damage_number_instance = damage_number.instantiate()
	damage_number_instance.position = pos
	get_tree().root.add_child(damage_number_instance)
	damage_number_instance.spawn(dmg)

func checkLifeLine():
	if enemy_health <= 0 and dead == false:
		dead = true

func _on_timer_timeout() -> void:
	timerFlag = false
	current_state = State.ATTACK

func _on_captured_timer_timeout() -> void:
	$GunPivot/CapturedCharge.emitting = false
	current_state = State.ATTACK
	await get_tree().create_timer(1.5).timeout
	dead = true

# --- Helpers ---

func can_see_player() -> bool:
	var dist = global_position.distance_to(player.global_position)
	if dist > detection_range: return false
	
	# Point the RayCast eyes at the player
	eyes.look_at(player.global_position, Vector3.UP, true) # Look at chest/head
	eyes.force_raycast_update()
	
	if eyes.is_colliding():
		return eyes.get_collider().is_in_group("Player")
	return false
