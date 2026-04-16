extends Area3D

@export var isCrit: bool = false

signal damage_taken(damage: float, type: String)

func hit(damage, type):
	if isCrit:
		damage *= 1.5
	damage_taken.emit(damage, type)
