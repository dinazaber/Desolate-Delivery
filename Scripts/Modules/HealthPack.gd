extends RigidBody3D

var is_held: bool = false
var is_destroyed: bool = false

@export var orb_count: int = 3

var orb = load("res://Scenes/Objects/HealthOrb.tscn")
var orb_instance

# ==================== can't use shoot reactable group, it doesn't react to aoe nor can i make it so
func hit(_a,_b,_c,_d):
	if is_destroyed: return
	spawnOrbs()

func damage_taken(_a,_b,_c,_d):
	if is_destroyed: return
	spawnOrbs()
# =====================

func spawnOrbs():
	is_destroyed = true
	
	for i in range(orb_count):
		orb_instance = orb.instantiate()
		get_tree().root.add_child(orb_instance)
		orb_instance.global_position = global_position
		
		orb_instance.apply_central_impulse(Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5)).normalized() * randf_range(5.0, 10.0))
	
	$AnimationPlayer.play("destroy&update")

func throw(direction, force):
	is_held = false
	var lim = 1.0 if mass > 0.5 else mass
	apply_central_impulse(direction * force / 10.0 * lim)
	apply_torque_impulse(Vector3(randf(), randf(), randf()) * mass * 0.01)

# --- Anti-Error Function Dump ---

func can_let_go() -> bool:
	return true
