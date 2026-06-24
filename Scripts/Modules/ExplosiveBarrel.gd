@tool
extends RigidBody3D

var is_held: bool = false

@export_range(0.1, 10.0) var total_scale: float = 1.0:
	set(value):
		total_scale = value
		$MeshInstance3D.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		$MeshInstance3D.position = Vector3(0.0, 0.0, 0.4) * total_scale
		$CollisionShape3D.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		$Area3D.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		inertia = Vector3(0.9,2.5,0.9) * mass

func throw():
	is_held = false
	var force = 100
	var lim = 1.0 if mass > 0.5 else mass
	apply_central_impulse(-global_transform.basis.z * force * lim)
	apply_torque_impulse(Vector3(randf(), randf(), randf()) * mass)

func can_let_go() -> bool:
	if $Area3D.has_overlapping_bodies():
		var bodies = $Area3D.get_overlapping_bodies()
		var is_player: bool = false
		for body in bodies:
			if body.is_in_group("Player"):
				is_player = true
		return !is_player
	else: return true

func hit(_a, _b): #Make explosion pls, I don't want to break something
	pass
