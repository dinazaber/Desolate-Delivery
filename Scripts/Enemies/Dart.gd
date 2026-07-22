extends Node3D


@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var doorF: RigidBody3D = $AnimRotAssist/PodHolder/DoorF
@onready var doorB: RigidBody3D = $AnimRotAssist/PodHolder/DoorB


func _ready() -> void:
	$AnimRotAssist/PodHolder.rotation.y = randf() * PI
	await get_tree().create_timer(1.0).timeout
	anim.play("arrive")
	await anim.animation_finished
	$trauma_causer.cause_trauma()
	anim.play("open")

func eject_doors() -> void:
	doorF.freeze = false
	doorB.freeze = false
	
	var dir: Vector3 = $AnimRotAssist/PodHolder.global_transform.basis.z
	doorF.apply_central_impulse(150.0 * randf_range(0.8, 1.2) * -dir)
	doorB.apply_central_impulse(150.0 * randf_range(0.8, 1.2) * dir)
