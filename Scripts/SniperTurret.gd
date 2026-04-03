extends Node3D

# --- Settings ---
enum State { IDLE, ATTACK }
var current_state = State.IDLE

@export var detection_range = 15
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
			State.ATTACK:
				process_attack_state(delta)
	else:
		process_dead_state()


func process_idle_state():
	if (can_see_player() or damagedByPlayer == true) and player.dead == false:
		current_state = State.ATTACK

func process_attack_state(delta):
	follow(delta)

func process_dead_state():
	pass


func follow(delta):
	look_target = lerp(look_target, player.global_position, delta * 3.5)
	gun.look_at(look_target, Vector3.UP, true)
	gun.rotation.x = clamp(gun.rotation.x, deg_to_rad(-20), deg_to_rad(20))
	gun.rotation_degrees = gun.rotation_degrees
	
	
	#First look_at does this part it seems but i won't delete it, just for case
	var mount_look_target = look_target
	mount_look_target.y = mount.global_position.y
	mount.look_at(mount_look_target, Vector3.UP)

func hit(recieved_damage, type):
	if type == "player":
		damagedByPlayer = true
	enemy_health -= recieved_damage
	checkLifeLine()

func get_pounded(recieved_damage): # DONT REMOVE still needed so the ground pound wont cause errors
	enemy_health -= recieved_damage
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
	eyes.look_at(player.global_position, Vector3.UP, true) # Look at chest/head
	eyes.force_raycast_update()
	
	if eyes.is_colliding():
		return eyes.get_collider().is_in_group("Player")
	return false

# --- Anti-Error Function Dump ---

func knockBack(_a, _b, _c):
	pass
