extends Area3D

@export var isCrit: bool = false


func _physics_process(_delta: float) -> void:
	pass

func hit(damage, isPlayer, type, pos):
	if !owner: return
	
	if isCrit:
		damage *= 1.5
	owner.damage_taken(damage, isPlayer, type, pos)

func shot():
	owner.shot()
