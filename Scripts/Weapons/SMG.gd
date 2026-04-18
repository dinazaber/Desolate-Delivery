extends Node3D

#gun stats
@export var damage = 15
@export var recoil = 0.4
@export var camera: Area3D
@export var playerRay: RayCast3D

@onready var anim = $AnimationPlayer

func draw():
	anim.play("draw")

func undraw():
	if anim.is_playing():
		await anim.animation_finished
	anim.play("undraw")
	await anim.animation_finished

func shoot():
	if !anim.is_playing():
		anim.play("shoot")
		camera.add_trauma(recoil)
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
