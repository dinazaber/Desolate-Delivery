@tool
extends Area3D

@export var trauma_amount: float = 1.0
@export var sphere_radius: float = 2.0:
	set(value):
		sphere_radius = value
		$CollisionShape3D.shape.radius = sphere_radius
		$CollisionShape3D.set("debug_color", Color.GREEN)

func cause_trauma():
	var trauma_areas = get_overlapping_areas()
	for area in trauma_areas:
		if area.has_method("add_trauma"):
			area.add_trauma(trauma_amount)

	
