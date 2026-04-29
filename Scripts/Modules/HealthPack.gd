extends RigidBody3D

var is_held: bool = false

@export var heal_amount: float = 20.0

@onready var gravitateRange = $GravitateRange
@onready var pickupRange = $PickupRange


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !is_held and gravitateRange.has_overlapping_bodies():
		var bodies = gravitateRange.get_overlapping_bodies()
		var playerCount: int = 0
		var player
		for body in bodies:
			if body.is_in_group("Player"):
				player = body
				playerCount += 1
		
		if playerCount:
			if player.player_health < player.PLAYER_MAX_HEALTH:
				gravity_scale = 0.6
				var dir: Vector3 = player.global_position - global_position
				apply_central_force(dir * dir.length() * 0.6)
				apply_torque_impulse(Vector3(randf(), randf(), randf()) * mass * 0.001)
				
				if !is_held and pickupRange.has_overlapping_bodies():
					bodies = pickupRange.get_overlapping_bodies()
					playerCount = 0
					for body in bodies:
						if body.is_in_group("Player"):
							player = body
							playerCount += 1
					if playerCount:
						player.heal(heal_amount)
						queue_free()
		else:
			gravity_scale = 1.0
	else:
		gravity_scale = 1.0

func throw(direction, force):
	is_held = false
	var lim = 1.0 if mass > 0.5 else mass
	apply_central_impulse(direction * force / 10.0 * lim)
	apply_torque_impulse(Vector3(randf(), randf(), randf()) * mass * 0.01)

# --- Anti-Error Function Dump ---

func hit(_a,_b):
	pass

func can_let_go() -> bool:
	return true
