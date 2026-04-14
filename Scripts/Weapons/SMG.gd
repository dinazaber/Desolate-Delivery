extends Node3D

#gun stats
@export var damage = 15
@export var recoil = 0.3
@export var camera: Area3D
@export var playerRay: RayCast3D

@onready var anim = $AnimationPlayer

func shoot():
	if !anim.is_playing():
		anim.play("Shoot")
		camera.add_trauma(recoil)
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
