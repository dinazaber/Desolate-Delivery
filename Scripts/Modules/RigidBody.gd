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
		inertia = Vector3(1.0,3.0,1.0) * mass

func knockBack(direction, _a, _b): ## used by steamer only
	is_held = false
	var lim = 1.0 if mass > 0.5 else mass
	apply_central_impulse(direction * 60.0 * lim)

func can_let_go() -> bool:
	return !$Area3D.has_overlapping_bodies()


# --- Anti-Error Function Dump ---
func hit(_a, _b):
	pass
