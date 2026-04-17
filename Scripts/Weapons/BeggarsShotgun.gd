extends Node3D

@export var damage = 40
@export var recoil = 1
@export var mag = 4
@export var camera: Area3D
@export var playerRay: RayCast3D

var shotNum = 0

@onready var anim = $AnimationPlayer

func draw():
	anim.play("draw")

func undraw():
	if anim.is_playing():
		await anim.animation_finished
	anim.play("undraw")
	await anim.animation_finished

func charge():
	if !anim.is_playing():
		if shotNum < mag and !anim.is_playing():
			anim.play("load")
			await anim.animation_finished
			shotNum += 1
					
func shoot():
	if anim.is_playing(): await anim.animation_finished
	while shotNum > 0:
		if shotNum > 1: anim.play("shootConsecutive")
		else: anim.play("shootLast")
		shotNum -= 1
		if playerRay.is_colliding():
			if playerRay.get_collider().is_in_group("Enemy"):
				playerRay.get_collider().hit(damage, "player")
			if playerRay.get_collider().is_in_group("ShotReactable"):
				playerRay.get_collider().shot()
		camera.add_trauma(recoil)
		await anim.animation_finished
