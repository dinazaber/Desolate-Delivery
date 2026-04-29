extends Node3D

@export var damage: float = 50.0

@export var camera: Area3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area = $PunchArea
@onready var playerPos = $PlayerPos

var in_action: bool = false


func punch():
	in_action = true
	if !anim.is_playing():
		anim.play("punch")
		await get_tree().create_timer(0.15).timeout
		
		var bodies = []
		if area.has_overlapping_bodies():
			bodies += area.get_overlapping_bodies()
		if !bodies.is_empty():
			hitstop(len(bodies))
			for body in bodies:
				if body.has_method("damage_taken") and !body.is_in_group("Player"):
					body.damage_taken(damage, true)
				if body.has_method("knockBack"):
					body.knockBack((body.global_position - playerPos.global_position).normalized(), damage/10, 0.25)
				if body.has_method("throw"):
					body.throw((body.global_position - playerPos.global_position).normalized(), 20.0)
	
	if anim.is_playing():
		await anim.animation_finished
	in_action = false

func hitstop(bodyCount):
	if anim.is_playing():
		camera.add_trauma(2 * bodyCount)
		anim.speed_scale = 0.2
		await get_tree().create_timer(0.06).timeout
		anim.speed_scale = 1.0
