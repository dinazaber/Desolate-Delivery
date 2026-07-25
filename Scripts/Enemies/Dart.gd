extends Node3D


@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var doorF: RigidBody3D = $AnimRotAssist/PodHolder/DoorF
@onready var doorB: RigidBody3D = $AnimRotAssist/PodHolder/DoorB
@onready var player = get_tree().get_first_node_in_group("Player")


func _ready() -> void:
	rotation.y += randf() * deg_to_rad(10.0)
	
	spawn()


func spawn() -> void:
	await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
	
	player.dart_warning()
	anim.play("arrive", -1, 1.35)
	await anim.animation_finished
	$trauma_causer.cause_trauma()
	anim.play("open")

func eject_doors() -> void:
	doorF.freeze = false
	doorB.freeze = false
	
	var dir: Vector3 = $AnimRotAssist/PodHolder.global_transform.basis.z
	doorF.apply_central_impulse(175.0 * randf_range(0.8, 1.2) * -dir)
	doorB.apply_central_impulse(175.0 * randf_range(0.8, 1.2) * dir)
