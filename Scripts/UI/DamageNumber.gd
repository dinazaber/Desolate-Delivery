extends Node3D

var rand_dir: Vector3 = Vector3.ZERO
var shake: float = 0.0


func spawn(damage):
	$Label3D.text = str(int(roundf(damage)))
	$Label3D.modulate = Color(255, 215 - min(damage, 100), 80, 180) / 255
	
	$AnimationPlayer.play("scale", -1, randf_range(0.7, 1.0) * clamp(70/damage, 0.6, 1.0))
	
	rand_dir = Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5)).normalized() * randf_range(5.0, 7.0)
	
	if damage >= 60.0: shake = min((damage - 60.0) / 40.0, 1.2) + 3.0
	
	await $AnimationPlayer.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += rand_dir * delta
	rand_dir.y -= randf_range(15.0, 20.0) * delta
	
	if shake: $Label3D.position = Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1),) * shake * delta
