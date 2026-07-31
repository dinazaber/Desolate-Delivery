extends Node3D


@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var doorF: RigidBody3D = $AnimRotAssist/PodHolder/DoorF
@onready var doorB: RigidBody3D = $AnimRotAssist/PodHolder/DoorB
@onready var player = get_tree().get_first_node_in_group("Player")

@export_category("ENEMIES") # use path to file, not compacted scene
@export_file("*.tscn") var frontRight
@export_file("*.tscn") var frontLeft
@export_file("*.tscn") var backRight
@export_file("*.tscn") var backLeft
var enemies = []

const spawn_trans = [Vector3(-0.65, 2.3, 0.75), PI/2,
					 Vector3(-0.65, 2.3, -0.75), PI/2,
					 Vector3(0.65, 2.3, 0.75), -PI/2,
					 Vector3(0.65, 2.3, -0.75), -PI/2]


func _ready() -> void:
	rotation.y += randf() * deg_to_rad(10.0)
	
	if frontRight: enemies.append(load(frontRight))
	else: enemies.append(null)
	if frontLeft: enemies.append(load(frontLeft))
	else: enemies.append(null)
	if backRight: enemies.append(load(backRight))
	else: enemies.append(null)
	if backLeft: enemies.append(load(backLeft))
	else: enemies.append(null)


func start() -> void:
	player.dart_warning()
	anim.play("arrive", -1, 1.35)
	await anim.animation_finished
	$trauma_causer.cause_trauma()
	anim.play("open")

func eject_doors() -> void:
	spawn()
	
	doorF.freeze = false
	doorB.freeze = false
	
	var dir: Vector3 = $AnimRotAssist/PodHolder.global_transform.basis.z
	doorF.apply_central_impulse(175.0 * randf_range(0.8, 1.2) * -dir)
	doorB.apply_central_impulse(175.0 * randf_range(0.8, 1.2) * dir)

func spawn() -> void: # spawns enemies
	for i in range(4):
		if enemies[i]:
			var instance = enemies[i].instantiate()
			instance.position = spawn_trans[2*i]
			instance.rotation.y = spawn_trans[2*i+1]
			add_child(instance)
