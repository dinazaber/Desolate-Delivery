extends Node3D

var speed = 80.0
var velocity = Vector3.ZERO
var spear_damage = 40

var stuck: bool = false
var stuck_pos = Vector3.ZERO
var got_shot: bool = false
var parented: bool = false

@onready var ray: RayCast3D = $RayCast3D
@onready var spear: MeshInstance3D = $SpearMesh


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider:
			if !stuck:
				stuck_pos = position - collider.position
				if collider.is_in_group("Enemy"):
					collider.hit(spear_damage, "player")
			#ray.visible = false
			stuck = true
			position = collider.position + stuck_pos
	else:
		position += velocity * delta

func set_velocity(target):
	look_at(target)
	velocity = position.direction_to(target) * speed

func _on_timer_timeout() -> void:
	queue_free()


# --- Anti-Error Function Dump ---

func hit(_a,_b):
	pass

func knockBack(_a, _b, _c):
	pass
