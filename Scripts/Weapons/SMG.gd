extends Node3D
@onready var anim = $AnimationPlayer
@export var camera: Area3D
@export var playerRay: RayCast3D
@export var smg_recoil = 0.3
@export var smg_damage = 15
func shoot():
	if !anim.is_playing():
		anim.play("Shoot")
		camera.add_trauma(smg_recoil)
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(smg_damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
