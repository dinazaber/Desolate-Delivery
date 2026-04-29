extends Area3D

@export var isCrit: bool = false

signal damage_taken(damage, type) #Godot sends many errors when deleting this, going to shprot so if you can solve this it will be cool

func hit(damage, isPlayer):
	if isCrit:
		damage *= 1.5
	owner.damage_taken(damage, isPlayer)
