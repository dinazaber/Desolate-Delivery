extends Area3D

@export var isCrit: bool = false

func hit(damage, isPlayer, type, pos):
	if isCrit:
		damage *= 1.5
	owner.damage_taken(damage, isPlayer, type, pos)

func shot():
	owner.shot()
