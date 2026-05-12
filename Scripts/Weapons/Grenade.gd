extends RigidBody3D

var got_shot: bool = false
var is_held: bool = false
var explode_on_contact: bool = false
var exploded: bool = false

@onready var smoke: GPUParticles3D = $Smoke
@onready var fire: GPUParticles3D = $Fire
@onready var debris: GPUParticles3D = $Debris

@onready var explosion_box_small = $ExplosionBox1
@onready var explosion_box_big = $ExplosionBox2
var current_exposion_box

@export var grenade_damage_small: float = 80.0
@export var grenade_damage_big: float = 120.0
var current_damage: float

const EXPLOSION_R_SMALL: float = 3.5
const EXPLOSION_R_BIG: float = 5.0
var current_explosion_radius: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	explosion_box_small.visible = false
	explosion_box_big.visible = false
	current_exposion_box = explosion_box_small
	current_damage = grenade_damage_small
	current_explosion_radius = EXPLOSION_R_SMALL
	$hitBox_physics.scale = Vector3.ONE * 3.0
	await get_tree().create_timer(0.15).timeout
	$hitBox_physics.scale = Vector3.ONE

func shot():
	got_shot = true
	explosion_box_small.visible = false
	explosion_box_big.visible = true
	current_exposion_box = explosion_box_big
	current_damage = grenade_damage_big
	current_explosion_radius = EXPLOSION_R_BIG
	if !exploded:
		explode()

func explode():
	var bodies = []
	exploded = true
	$GenadeMesh.visible = false
	$hitBox_physics.visible = false
	
	$trauma_causer.cause_trauma()
	if current_exposion_box.has_overlapping_bodies(): bodies += current_exposion_box.get_overlapping_bodies()
	if !bodies.is_empty():
		for body in bodies:
			var dist: float = global_position.distance_to(body.global_position)
			var coef: float
			
			if dist <= 1.0: coef = 1.0
			elif 1.0 < dist and dist < current_explosion_radius - 1:
				coef = (0.5 * (dist - 1)) / (2 - current_explosion_radius) + 1
			else: coef = 0.5
			
			if body.has_method("damage_taken"):
				body.damage_taken(current_damage * coef, true)
			
			var dir: Vector3 = (body.global_position - global_position).normalized()
			var force: float = current_damage * coef / 10.0
			if body.has_method("knockBack"):
				body.knockBack(dir, force, true, 0.3)
			if body.has_method("throw"):
				body.throw(dir, 40.0 * coef)
	
	if got_shot:
		debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	await get_tree().create_timer(2.0).timeout
	
	queue_free()

func _physics_process(_delta: float) -> void:
	if explode_on_contact and !got_shot and !exploded:
		if get_contact_count():
			explosion_box_small.visible = true
			explosion_box_big.visible = false
			explode()

func _on_timer_timeout() -> void:
	if !got_shot and !exploded:
		explosion_box_small.visible = true
		explosion_box_big.visible = false
		explode()

func throw(direction, force):
	is_held = false
	explode_on_contact = true
	var lim = 1.0 if mass > 0.5 else mass
	apply_central_impulse(direction * force * lim)
	apply_torque_impulse(Vector3(randf(), randf(), randf()) * mass)

# --- Anti-Error Function Dump ---

func hit(_a,_b):
	pass

func can_let_go() -> bool:
	return true
