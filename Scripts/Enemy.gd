extends CharacterBody3D

# --- Settings ---
enum State { IDLE, CHASE, ATTACK }
var current_state = State.IDLE

@export var speed = 3.5
@export var attack_distance = 2 # Short distance for sword
@export var detection_range = 15
@export var enemy_damage = 30
@export var enemy_health = 100

# --- Nodes ---
@onready var sprite = $AnimatedSprite3D
@onready var eyes = $RayCast3D
@onready var sword_ray = $SwordRay
@onready var navAgent = $NavigationAgent3D
@onready var player = get_tree().get_first_node_in_group("Player")

# --- Variables ---
var inTransition: bool = false
var isInAttack: bool = false
var damagedByPlayer: bool = false
var dead: bool = false



func _physics_process(delta):
	if !is_on_floor():
		velocity.y -= 20 * delta
	# Fallback if player is missing
	if not player: return
	
	if !dead:
		match current_state:
			State.IDLE:
				process_idle_state()
			State.CHASE:
				process_chase_state()
			State.ATTACK:
				process_attack_state()
	else:
		process_dead_state()

# --- State Logic ---

func process_idle_state():
	if inTransition: return
	
	sprite.play("Idle0")
	velocity = Vector3.ZERO # Stop movement
	
	if (can_see_player() or damagedByPlayer == true) and player.dead == false:
		inTransition = true
		sprite.play("Equip")
		await sprite.animation_finished
		inTransition = false
		current_state = State.CHASE

func process_chase_state():
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
	if sword_ray.is_colliding():
		current_state = State.ATTACK
	elif !can_see_player() and dist > detection_range and !damagedByPlayer:
		inTransition = true
		sprite.play_backwards("Equip")
		await sprite.animation_finished
		inTransition = false
		current_state = State.IDLE

func process_attack_state():
	# Stop movement during the swing
	velocity = Vector3.ZERO
	
	# Decide: Player forever-napping or keep attaking?
	if !player.dead and !isInAttack:
		isInAttack = true
		sprite.play("Attack1")
		attack()
	
	await sprite.animation_finished
	
	isInAttack = false
	
	# Decide: Chase again or keep attacking?
	if player.dead == true:
		current_state = State.IDLE
	
	if global_position.distance_to(player.global_position) > attack_distance:
		current_state = State.CHASE


func process_dead_state(): # gotta make death anim   Zzzzz
	pass 

func attack():
	await sprite.animation_finished
	if sword_ray.is_colliding():
		#var pos = smg_ray.get_collision_point()
		#var normal = smg_ray.get_collision_normal()
		if sword_ray.get_collider().is_in_group("Player"):
			sword_ray.get_collider().hit(enemy_damage, "enemy")

func hit(recieved_damage, type):
	if type == "player":
		damagedByPlayer = true
	enemy_health -= recieved_damage
	checkLifeLine()

func get_pounded(recieved_damage):
	enemy_health -= recieved_damage
	# Push away
	velocity.y += 5
	speed = -30
	await get_tree().create_timer(0.1).timeout # this is so shitty D:
	speed = 4
	
	checkLifeLine()

func checkLifeLine():
	if enemy_health <= 0 and dead == false:
		print("enemy felled")
		dead = true
		queue_free()


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
