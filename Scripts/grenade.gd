extends RigidBody3D

var got_shot: bool = false

var explosion = load("res://Scenes/Explosion.tscn")
var instance

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
	explosion_box_small.visible = true
	explosion_box_big.visible = false
	current_exposion_box = explosion_box_small
	current_damage = grenade_damage_small

func shot():
	got_shot = true
	explosion_box_small.visible = false
	explosion_box_big.visible = true
	current_exposion_box = explosion_box_big
	current_damage = grenade_damage_big
	explode()

func explode():
	if current_exposion_box.has_overlapping_bodies():
		var bodies = current_exposion_box.get_overlapping_bodies()
		for body in bodies:
			body.hit(current_damage, "player")
	
	
	$GenadeMesh.visible = false
	if got_shot:
		debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	await get_tree().create_timer(2.0).timeout
	
	print("boom")
	queue_free()

func hit(_a,_b):
	pass

func _on_timer_timeout() -> void:
	if !got_shot:
		explode()
