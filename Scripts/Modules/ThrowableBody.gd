@tool
extends RigidBody3D

var thrown: bool = false
var is_held: bool = false
var damage: int

@export_range(0.1, 10.0) var total_scale: float = 1.0:
	set(value):
		total_scale = value
		$BoxCrate.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		$CollisionShape3D.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		$Area3D.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		$Particles.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		inertia = Vector3.ONE * 0.5 * mass

func throw(direction, force):
	if is_held and force > 50:
		thrown = true
		damage = force / 2
	is_held = false
	var lim = 1.0 if mass > 0.5 else mass
	apply_central_impulse(direction * force * lim)
	apply_torque_impulse(Vector3(randf(), randf(), randf()) * mass)

func can_let_go() -> bool:
	if $Area3D.has_overlapping_bodies():
		var bodies = $Area3D.get_overlapping_bodies()
		var is_player: bool = false
		for body in bodies:
			if body.is_in_group("Player"):
				is_player = true
		return !is_player
	else: return true


func _on_body_entered(body: Node) -> void:
	if !thrown: return
	freeze = true
	$MeshInstance3D.hide()
	#$BlobShadow.hide()
	
	if body.has_method("damage_taken"):
		body.damage_taken(damage, true, "object", global_position)
	
	# Each object will have dedicated function for particles
	$Particles/CrateBox/BreakCrate.emitting = true
	$Particles/CrateBox/Dust.emitting = true
	await get_tree().create_timer(0.5).timeout
	
	queue_free()
