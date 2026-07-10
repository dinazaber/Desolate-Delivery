extends Node3D

func damage_taken(_a, _b, _c, _d):
	$BoardPart.hide()
	$Particles/BreakCrate.emitting = true
	$Particles/Dust.emitting = true
	$CollisionShape3D.disabled = true
	#No rigid body needed for my opinion
