extends Area3D

@export var isCrit: bool = false

func hit(damage, isPlayer):
	if isCrit:
		damage *= 1.5
	owner.damage_taken(damage, isPlayer)

func shot():
	owner.shot()
