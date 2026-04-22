@tool
extends RigidBody3D

@export_range(0.1, 10.0) var total_scale: float = 1.0:
	set(value):
		total_scale = value
		$MeshInstance3D.scale = Vector3(total_scale, total_scale, total_scale)
		$MeshInstance3D.position = Vector3(0.0, 0.0, 0.4 * total_scale)
		$CollisionShape3D.scale = Vector3(total_scale, total_scale, total_scale)
		inertia = Vector3(mass,mass,mass)
