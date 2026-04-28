extends Area3D

@export var damage_multiplier: float = 1.0

func hit(damage):
	damage *= damage_multiplier
	owner.damage_taken(damage)

func knockBack(direction, force, time):
	if owner.has_method("KnockBack"): owner.knockBack(direction, force, time)
