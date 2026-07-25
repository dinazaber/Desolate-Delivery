@tool
extends RigidBody3D

var is_held: bool = false
var exploded: bool = false
var health: float = 60.0

@onready var explosion_box: Area3D = $ExplosionBox
var explosion_radius: float = 0.0

@export var damage: float = 150.0
@export_range(0.1, 10.0) var total_scale: float = 1.0:
	set(value):
		total_scale = value
		
		for child in get_children():
			child.scale = Vector3.ONE * total_scale
		
		$Barrel.position = Vector3(0.0, 0.0, 0.4) * total_scale
		inertia = Vector3(0.9,2.5,0.9) * mass
		
		explosion_radius = $ExplosionBox/ExpCol.shape.radius * total_scale


func _physics_process(delta: float) -> void:
	if !exploded and health <= 0.0:
		explode()
	$Sizzel.amount_ratio = max(0.0, 2 * (0.5 - health / 60.0))**0.5
	if health < 30.0:
		health -= delta * 10.0

func throw(direction, force):
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

func hit(recieved_damage, _a, type, _b):
	if type == "heat": recieved_damage = 40.0
	
	health -= recieved_damage

func damage_taken(recieved_damage, _a, type, _b):
	if type == "heat": recieved_damage = 40.0
	
	health -= recieved_damage

func explode():
	var bodies = []
	exploded = true
	$Barrel.visible = false
	$CollisionShape3D.disabled = true
	freeze = true
	set_physics_process(false)
	
	$trauma_causer.cause_trauma()
	if explosion_box.has_overlapping_bodies(): bodies += explosion_box.get_overlapping_bodies()
	if !bodies.is_empty():
		for body in bodies:
			var dist: float = global_position.distance_to(body.global_position)
			var coef: float
			
			if dist <= 1.0: coef = 1.0
			elif 1.0 < dist and dist < explosion_radius - 1:
				coef = (0.5 * (dist - 1)) / (2 - explosion_radius) + 1
			else: coef = 0.5
			
			if body.has_method("damage_taken"):
				body.damage_taken(damage * coef, true, "explosion", body.global_position)
			
			var dir: Vector3 = (body.global_position - global_position).normalized()
			var force: float = damage * coef / 10.0
			if body.has_method("knockBack"):
				body.knockBack(dir, force, true, 0.3)
			if body.has_method("throw"):
				body.throw(dir, 50.0 * coef)
	
	$Sizzel.emitting = false
	$Smoke.emitting = true
	$Fire.emitting = true
	$Debris.emitting = true
	await get_tree().create_timer(2.0).timeout
	
	queue_free()
