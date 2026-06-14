@tool
extends Area3D

@export var falloff: bool = true
@export var trauma_amount = 1.0
@export var sphere_radius = 2.0:
	set(value):
		sphere_radius = value
		$CollisionShape3D.shape.radius = sphere_radius
		$CollisionShape3D.debug_color = Color.GREEN
		

func cause_trauma():
	var trauma_areas = get_overlapping_areas()
	for area in trauma_areas:
		if area.has_method("add_trauma"):
			var coef: float = 1.0
			if falloff:
				coef = clamp((sphere_radius - global_position.distance_to(area.global_position)) / sphere_radius, 0.2, 1.0)
				coef **= 2.0
			
			area.add_trauma(trauma_amount * coef)
