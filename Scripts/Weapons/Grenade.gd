extends RigidBody3D

var got_shot: bool = false
var is_held: bool = false
var exploded: bool = false

@onready var smoke: GPUParticles3D = $Smoke
@onready var fire: GPUParticles3D = $Fire
@onready var debris: GPUParticles3D = $Debris

@onready var explosion_box_small = $ExplosionBox1
@onready var explosion_box_big = $ExplosionBox2
var current_exposion_box

@export var grenade_damage_small = 80
@export var grenade_damage_big = 120
var current_damage

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	explosion_box_small.visible = false
	explosion_box_big.visible = false
	current_exposion_box = explosion_box_small
	current_damage = grenade_damage_small

func shot():
	got_shot = true
	explosion_box_small.visible = false
	explosion_box_big.visible = true
	current_exposion_box = explosion_box_big
	current_damage = grenade_damage_big
	if !exploded:
		explode()

func explode():
	exploded = true
	$GenadeMesh.visible = false
	$hitBox_shotTrigger.visible = false
	
	$trauma_causer.cause_trauma()
	if current_exposion_box.has_overlapping_bodies():
		var bodies = current_exposion_box.get_overlapping_bodies()
		for body in bodies:
			body.hit(current_damage, "player")
			body.knockBack((body.global_position - global_position).normalized(), current_damage/15, 0.1)
	
	if got_shot:
		debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	await get_tree().create_timer(2.0).timeout
	
	queue_free()

func _on_timer_timeout() -> void:
	if !got_shot and !exploded:
		explosion_box_small.visible = true
		explosion_box_big.visible = false
		explode()

func knockBack(direction, _a, _b): ## used by steamer only
	is_held = false
	var lim = 1.0 if mass > 0.5 else mass
	apply_central_impulse(direction * 60.0 * lim)

# --- Anti-Error Function Dump ---

func hit(_a,_b):
	pass

func can_let_go() -> bool:
	return true
