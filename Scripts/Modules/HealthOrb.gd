extends RigidBody3D

@export var heal_amount: float = 10.0

@onready var gravitateRange = $GravitateRange
@onready var pickupRange = $PickupRange

var player = null

func _on_gravitate_range_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"): player = body

func _on_pickup_range_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.heal(heal_amount)
		queue_free()

func _physics_process(_delta: float) -> void:
	linear_damp = clamp(linear_velocity.length(), 5.0, 10.0)
	
	if player:
		var dir: Vector3 = player.global_position - Vector3(0.0,0.25,0.0) - global_position
		apply_central_force(dir * clamp(dir.length(), 1.5, 2.0) * clamp(linear_velocity.length(), 0.5, 4.0))
