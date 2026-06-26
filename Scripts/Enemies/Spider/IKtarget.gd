@tool
extends Marker3D


@export var step_target: Marker3D
@export var step_distance: float = 1.5

@export var adjacent_target: Marker3D
@export var opposite_target: Marker3D

var is_stepping: bool = false


func _physics_process(_delta: float) -> void:
	if !is_stepping and !adjacent_target.is_stepping and abs(global_position.distance_to(step_target.global_position)) > step_distance:
	#if abs(global_position.distance_to(step_target.global_position)) > step_distance:
		step()
		opposite_target.step()

func step():
	var target_pos = step_target.global_position
	var half_way = (global_position + target_pos) / 2
	
	is_stepping = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", half_way + 1.2 * owner.basis.y, 0.15)
	tween.tween_property(self, "global_position", target_pos, 0.15)
	tween.tween_callback(func(): is_stepping = false)
	#await get_tree().create_timer(0.1).timeout
	#is_stepping = false
