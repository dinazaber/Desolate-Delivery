extends Node3D

# --- Settings ---
enum State { IDLE, AIM, ATTACK }
var current_state = State.IDLE

@export var detection_range = 50
@export var enemy_damage = 50
@export var enemy_health = 100

# --- Nodes ---
@onready var eyes = $RayCast3D
@onready var gunRay = $GunPivot/GunMesh/GunRay
@onready var player = get_tree().get_first_node_in_group("Player")

# --- Body Parts ---
@onready var mount = $MountMesh
@onready var gun = $GunPivot


# --- Variables ---
var inTransition: bool = false
var isInAttack: bool = false
var damagedByPlayer: bool = false
var dead: bool = false
var timerFlag: bool = false
var player_hit: bool = false
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	look_target = player.global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
			State.ATTACK:
				process_attack_state()
	else:
		process_dead_state()


func process_idle_state():
	if (can_see_player() or damagedByPlayer == true) and !player.dead and !isInAttack:
		current_state = State.AIM

func process_aim_state(delta):
	if !timerFlag:
		timerFlag = true
		$Timer.start()
		$GunPivot/Charge.restart()
		$GunPivot/Charge.emitting = true
	follow(delta)

func process_attack_state():
	$GunPivot/Beam.emitting = true
	$GunPivot/Beamies.emitting = true
	if gunRay.is_colliding():
		if gunRay.get_collider().is_in_group("Player") and !player_hit:
			player_hit = true
			gunRay.get_collider().hit(enemy_damage, "enemy")
	await get_tree().create_timer(0.6).timeout
	current_state = State.IDLE
	isInAttack = false

func process_dead_state():
	player.enemy_killed()
	queue_free()


func follow(delta):
	look_target = lerp(look_target, player.global_position, delta * 3.5)
	gun.look_at(look_target, Vector3.UP, true)
	gun.rotation.x = clamp(gun.rotation.x, deg_to_rad(-20), deg_to_rad(20))
	
	#First look_at does this part it seems but i won't delete it, just for case
	var mount_look_target = look_target
	mount_look_target.y = mount.global_position.y
	mount.look_at(mount_look_target, Vector3.UP)

func hit(recieved_damage, type):
	if type == "player":
		damagedByPlayer = true
	enemy_health -= recieved_damage
	checkLifeLine()

func checkLifeLine():
	if enemy_health <= 0 and dead == false:
		dead = true

func _on_timer_timeout() -> void:
	timerFlag = false
	isInAttack = true
	player_hit = false
	current_state = State.ATTACK

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

# --- Anti-Error Function Dump ---

func knockBack(_a, _b, _c):
	pass
