extends BoneAttachment3D


@export var ragdollable: bool = true
@export var mass: float = 1.0

var rigid: bool = false
var skeleton: Skeleton3D
var hitboxes = []


func _ready() -> void:
	skeleton = get_skeleton()

	var children = get_children()
	for child in children:
		if child is Area3D and child.is_in_group("Enemy"): hitboxes.append(child)

func ragdoll():
	print("a")
	if rigid or !ragdollable: return
	rigid = true
	
	# physics setup
	var rigidBody = RigidBody3D.new()
	get_tree().root.add_child(rigidBody)
	rigidBody.global_position = global_position
	rigidBody.collision_layer = 6
	rigidBody.collision_mask = 6
	rigidBody.gravity_scale = 0.0
	
	# reparanting - this method counts on the fact that hitboxes' only children are collision shapes!
	for hitbox in hitboxes:
		var collisions = hitbox.get_children()
		for collision in collisions:
			collision.reparent(rigidBody)
		hitbox.queue_free()
	
	override_pose = false
	reparent(rigidBody)
	external_skeleton = get_path_to(skeleton)
	override_pose = true
	
	rigidBody.set_script("res://Scripts/Modules/RigidBody.gd")
	
	rigidBody.apply_central_impulse(5 * Vector3.ONE * randf_range(-2, 2))
