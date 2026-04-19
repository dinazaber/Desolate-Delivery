@tool
extends RigidBody3D

@export_range(0.1, 10.0) var total_scale: float = 1.0:
	set(value):
		total_scale = value
		$MeshInstance3D.scale = Vector3(total_scale, total_scale, total_scale)
		$CollisionShape3D.scale = Vector3(total_scale, total_scale, total_scale)
