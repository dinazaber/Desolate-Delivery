extends Node3D

@export var damage: float = 35.0

@export var camera: Area3D
@export var player: CharacterBody3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area = $PunchArea
@onready var playerPos = $PlayerPos

var in_action: bool = false


func punch(speed): # set speed to zero if not dashing
	in_action = true
	if !anim.is_playing():
		anim.play("punch")
		if speed:
			var direction = -camera.global_transform.basis.z.normalized()
			player.knockBack(direction, 2.5, false, 0.0)
			
			area.scale = Vector3.ONE * 2.0
			
			$Drill/LungeParticles.restart()
			$Drill/LungeParticles.emitting = true
		await get_tree().create_timer(0.15).timeout
		
		var bodies = []
		if area.has_overlapping_bodies():
			bodies += area.get_overlapping_bodies()
		if !bodies.is_empty():
			hitstop(len(bodies))
			for body in bodies:
				if body.has_method("damage_taken") and !body.is_in_group("Player"):
					body.damage_taken(damage + speed, true)
				if body.has_method("knockBack"):
					body.knockBack((body.global_position - playerPos.global_position).normalized(), (damage + speed)/10, true, 0.25)
				if body.has_method("throw"):
					body.throw((body.global_position - playerPos.global_position).normalized(), 20.0)
				
				if body.is_in_group("Enemy"):
					if !player.is_on_floor() and player.drillJump:
						player.knockBack(Vector3.UP, speed/2.0, false, 0.0)
		
		area.scale = Vector3.ONE
	
	if anim.is_playing():
		await anim.animation_finished
	in_action = false

func hitstop(bodyCount):
	camera.add_trauma(2.5 * bodyCount)
	if anim.is_playing():
		anim.speed_scale = 0.1
		await get_tree().create_timer(0.06).timeout
		anim.speed_scale = 1.0
