extends CharacterBody3D


# --- Settings ---
enum State { IDLE, CHASE, CHARGE, ATTACK }
var current_state = State.IDLE

@export var speed: float = 7.0
@export var attack_charge_speed: float = 15.0
@export var attack_start_distance: float = 12.0 # when start charging
@export var detection_range: float = 25.0
@export var enemy_attack_damage: float = 40.0
@export var enemy_health: float = 70.0
@export var health_orb_reward: int = 2

# --- Nodes ---
@onready var animation = $AnimationPlayer
@onready var eyes = $Eyes
@onready var damageArea: Area3D = $DamageArea
@onready var navAgent: NavigationAgent3D = $NavigationAgent3D
@onready var skeleton: Skeleton3D = $SkeliHolder/Skeleton3D
@onready var player = get_tree().get_first_node_in_group("Player")

# --- Variables ---
var inTransition: bool = false
var isInAttack: bool = false
var damagedByPlayer: bool = false
var dead: bool = false
var knocked: bool = false
var stunned: bool = false
var dist = 9999.0
var look_target_desired
var look_target
var smooth_speed: float = 0.0

# --- Load ---
var damage_number = load("res://Scenes/UI/DamageNumber.tscn")
var damage_number_instance


func _ready() -> void:
	look_target_desired = $Eyes/Rayend.global_position
	look_target = look_target_desired

func _physics_process(delta: float) -> void:
	# Apply basic gravity if it's airborne
	if !is_on_floor():
		velocity.y -= 15.0 * delta
		
	# Fallback if player hasn't spawned yet
	if !player:
		player = get_tree().get_first_node_in_group("Player")
		return
	
	dist = global_position.distance_to(player.global_position)
	
	if !dead:
		match current_state:
			State.IDLE:
				process_idle_state(delta)
			State.CHASE:
				process_chase_state(delta)
			State.CHARGE:
				process_charge_state(delta)
			State.ATTACK:
				process_attack_state(delta)
	else:
		process_dead_state()
	
	# tilt
	if velocity.length() > 0.01:
		var rot_dot = -global_transform.basis.z
		rot_dot.y = 0.0
		rot_dot = rot_dot.normalized()
		rot_dot = rot_dot.dot(Vector3(velocity.x, 0.0, velocity.z).normalized())
		skeleton.rotate_object_local(Vector3(-1,0,0), (velocity.length() / speed) * rot_dot * delta * 12.0)
	
	# dirt particles
	if velocity.length() > 0.3 and is_on_floor():
		$dustTrail.emitting = true
		$dustTrail.global_transform.basis.z = -global_transform.basis.z
		$dustTrail.amount_ratio = clamp(velocity.length() / 15.0, 0.0, 1.0)
		$dustTrail.process_material.initial_velocity = Vector2(velocity.length() / 2, velocity.length() / 2 + 2.0)
	else:
		$dustTrail.emitting = false
	
	move_and_slide()


func process_idle_state(delta):
	if inTransition or stunned: return
	
	if !knocked:
		velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	
	if (can_see_player() or damagedByPlayer) and !player.dead:
		current_state = State.CHASE

func process_chase_state(delta):
	if inTransition or stunned: return
	
	if player.dead:
		current_state = State.IDLE
		return
	
	navAgent.target_position = player.global_position
	
	# Check if the path is ready
	if navAgent.is_navigation_finished(): return
	
	var nextPathPos = navAgent.get_next_path_position()
	
	# Rotate to look at player (Y-axis only)
	#look_target_desired = nextPathPos
	#look_target_desired.y = global_position.y
	#look_target = lerp(look_target, look_target_desired, delta * 3.5)
	#look_at(look_target, Vector3.UP)
	var direction_to_pos = global_position.direction_to(nextPathPos)
	var target_angle = atan2(direction_to_pos.x, direction_to_pos.z)
	var angle_dif = angle_difference(target_angle, global_rotation.y)
	global_rotation.y = rotate_toward(global_rotation.y, target_angle, PI * delta)
	rotation.z = rotate_toward(rotation.z, clamp(angle_dif / 4, -deg_to_rad(20.0), deg_to_rad(20.0)), PI * delta)
	
	# Move toward player
	var look_dir = global_transform.basis.z
	var dir = Vector3(look_dir.x, 0.0, look_dir.z).normalized()
	var turn_mod = abs(PI / (PI + (target_angle - global_rotation.y)))
	if !knocked:
		velocity.x = lerp(velocity.x, dir.x * speed * turn_mod, delta * 5.0)
		velocity.z = lerp(velocity.z, dir.z * speed * turn_mod, delta * 5.0)
	
	# Check transitions
	dist = global_position.distance_to(player.global_position)
	var player_xz_dir = Vector3((player.global_position - global_position).x, 0.0, (player.global_position - global_position).z)
	var dot = (global_transform.basis.z).normalized().dot(player_xz_dir.normalized())
	
	if dist <= attack_start_distance and can_see_player() and dot > 0.98:
		current_state = State.CHARGE
	elif !can_see_player() and dist > detection_range and !damagedByPlayer:
		current_state = State.IDLE

func process_charge_state(delta):
	if player.dead:
		current_state = State.IDLE
		return
	
	if !knocked:
		velocity.x = lerp(velocity.x, 0.0, delta * 5.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 5.0)
	
	if animation.current_animation == "": animation.play("charge")

func process_attack_state(delta):
	if stunned:
		velocity.x = lerp(velocity.x, 0.0, delta * 8.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 8.0)
		return
	
	# look at player's next position
	var prediction: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z) * (dist / attack_start_distance)
	var direction_to_pos = global_position.direction_to(player.global_position + prediction)
	var target_angle = atan2(direction_to_pos.x, direction_to_pos.z)
	var angle_dif = angle_difference(target_angle, global_rotation.y)
	global_rotation.y = rotate_toward(global_rotation.y, target_angle, PI / 1.25 * delta)
	rotation.z = rotate_toward(rotation.z, clamp(angle_dif / 4, -deg_to_rad(20.0), deg_to_rad(20.0)), PI * delta)
	
	var look_dir = global_transform.basis.z
	var dir = Vector3(look_dir.x, 0.0, look_dir.z).normalized()
	if !is_on_wall():
		velocity.x = lerp(velocity.x, dir.x * attack_charge_speed, delta * 15.0)
		velocity.z = lerp(velocity.z, dir.z * attack_charge_speed, delta * 15.0)
	elif get_wall_normal().angle_to(-global_transform.basis.z) < rad_to_deg(15.0):
		stunned = true
		velocity = Vector3.ZERO
		knockBack(get_wall_normal() + 0.5 * Vector3.UP, 5.0, false, 0.1)
		$attackRings.emitting = false
		animation.play("stunned")
		await animation.animation_finished
		stunned = false
		current_state = State.IDLE

func process_dead_state(): # gotta make death anim   Zzzzz
	player.enemy_killed(global_position, health_orb_reward)
	queue_free()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "charge": return
	
	$AttackTimeout.start()
	$attackRings.emitting = true
	current_state = State.ATTACK

func _on_attack_timeout_timeout() -> void:
	$attackRings.emitting = false
	current_state = State.IDLE

func _on_damage_area_body_entered(body: Node3D) -> void:
	if current_state != State.ATTACK or stunned or body == self: return
	
	if body.has_method("damage_taken"):
		body.damage_taken(enemy_attack_damage, false, "explosive", body.global_position)
	if body.has_method("knockBack"):
		body.knockBack((body.global_position - global_position + Vector3(0.0, 0.3, 0.0)).normalized(), 8.0, false, 0.3)
	if body.has_method("throw"):
		body.throw((body.global_position - global_position).normalized(), 30.0)

func knockBack(direction, force, _slowOnGround, time):
	knocked = true
	velocity += direction * force
	await get_tree().create_timer(time).timeout
	knocked = false

func damage_taken(recieved_damage, isPlayer, _type, pos):
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


# --- Helpers ---

func can_see_player() -> bool:
	if dist > detection_range: return false
	
	# Point the RayCast eyes at the player
	eyes.look_at(player.global_position) # Look at chest/head
	eyes.force_raycast_update()
	
	if eyes.is_colliding():
		return eyes.get_collider().is_in_group("Player")
	return false
