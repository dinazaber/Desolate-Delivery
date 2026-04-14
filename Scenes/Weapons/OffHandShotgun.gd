extends Node3D
signal knockBack(force: int, time: float)

@export var damage = 70
@export var recoil = 1.5
@export var mag = 4
@export var camera: Area3D
@export var playerRay: RayCast3D



@onready var anim = $AnimationPlayer

func shoot():
	if !anim.is_playing():
		anim.play("Draw")
		await anim.animation_finished
		anim.play("Shoot")
		camera.add_trauma(recoil)
		
		var direction = camera.global_transform.basis.z.normalized()
		
		knockBack.emit(direction, 10, 0.2)
		
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
		
		await anim.animation_finished
		anim.play_backwards("Draw")
