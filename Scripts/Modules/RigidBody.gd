extends RigidBody3D

var is_held: bool = false


func _ready() -> void:
	inertia = Vector3.ONE * mass**2 / 4
	angular_damp = 5.0

func throw(direction, force):
	is_held = false
	var lim = 1.0 if mass > 0.5 else mass
	apply_central_impulse(direction * force * lim)
	apply_torque_impulse(Vector3(randf(), randf(), randf()) * mass)


# --- Anti-Error Function Dump ---

func hit(_a,_b):
	pass

func can_let_go() -> bool:
	return true
