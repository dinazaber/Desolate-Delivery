@tool
extends RigidBody3D

var thrown: bool = false
var is_held: bool = false

@export_range(0.1, 10.0) var total_scale: float = 1.0:
	set(value):
		total_scale = value
		$MeshInstance3D.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		$CollisionShape3D.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		$Area3D.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		$Particles.scale = Vector3(1.0, 1.0, 1.0) * total_scale
		inertia = Vector3(0.9,2.5,0.9) * mass

#@onready var blob_shadow = $BlobShadow

func throw(direction, force):
	thrown = true
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
	#if blob_shadow: blob_shadow.hide()
	
	#if body.is_in_group("Enemy"):
	if body.has_method("damage_taken"):
		body.damage_taken(30.0, true, "object", global_position)
	
	# Each object will have dedicated function for particles
	$Particles/CrateBox/BreakCrate.emitting = true
	$Particles/CrateBox/Dust.emitting = true
	await get_tree().create_timer(0.5).timeout
	
	queue_free()
