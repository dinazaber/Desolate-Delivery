extends Node3D

var speed: float = 30.0
var velocity = Vector3.ZERO
var damage: float = 120.0

var exploded: bool = false

@onready var coll_area: Area3D = $CollisionArea
@onready var exp_area: Area3D = $ExplosionArea
@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	anim.play("fizzle", -1, -6, true)
	await get_tree().create_timer(0.05).timeout
	$lingers.emitting = true

func _physics_process(delta: float) -> void:
	if coll_area.has_overlapping_bodies():
		explode(coll_area.get_overlapping_bodies()[0].is_in_group("Enemy"))
	elif !exploded:
		velocity.y -= 15.0 * delta
		position += velocity * delta
		#position = lerp(position, position + velocity * delta, 60 * delta)

func set_velocity(dir):
	velocity = dir * speed

func explode(collided):
	if !exploded:
		exploded = true
		
		if collided:
			$explosion.emitting = true
			var bodies = []
			if exp_area.has_overlapping_bodies(): bodies += exp_area.get_overlapping_bodies()
			if !bodies.is_empty():
				for body in bodies:
					var dir = (body.global_position - global_position).normalized()
					
					if body.has_method("damage_taken"):
						body.damage_taken(damage, true)
					if body.has_method("knockBack"):
						body.knockBack(dir, damage/10, true, 0.3)
					if body.has_method("throw"):
						body.throw(dir, 25.0)
		
		anim.stop()
		anim.play("fizzle")
		$lingers.emitting = false
		await get_tree().create_timer($lingers.lifetime).timeout
		queue_free()

func _on_timer_timeout() -> void:
	explode(false)


# --- Anti-Error Function Dump ---

func hit(_a,_b):
	pass

func knockBack(_a, _b, _c):
	pass
