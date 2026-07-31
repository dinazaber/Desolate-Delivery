#@tool
extends Marker3D


@export var step_target: Marker3D
@export var step_distance: float = 1.8
@export var step_height: float = 1.2
@export var step_time: float = 0.12

@export var adjacent_target1: Marker3D
@export var adjacent_target2: Marker3D
@export var adjacent_target3: Marker3D
var adjacent_targets = []

@export var contact_check: ShapeCast3D

var is_stepping: bool = false
var offset_distance: float = 0.0


func _ready() -> void:
	if adjacent_target1: adjacent_targets.append(adjacent_target1)
	if adjacent_target2: adjacent_targets.append(adjacent_target2)
	if adjacent_target3: adjacent_targets.append(adjacent_target3)

func _physics_process(_delta: float) -> void:
	offset_distance = global_position.distance_to(step_target.global_position)
	
	var is_offset_biggest: bool = true
	var only_one_stepping: bool = true
	for target in adjacent_targets:
		if target.offset_distance > offset_distance: is_offset_biggest = false
		if target.is_stepping: only_one_stepping = false
	
	if !is_stepping and is_offset_biggest and only_one_stepping and (offset_distance > step_distance or !contact_check.is_colliding()):
	#if abs(global_position.distance_to(step_target.global_position)) > step_distance:
		step()

func step():
	var target_pos = step_target.global_position
	var half_way = (global_position + target_pos) / 2
	
	is_stepping = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", half_way + step_height * owner.basis.y, 0.12)
	tween.tween_property(self, "global_position", target_pos, 0.12)
	tween.tween_callback(func(): is_stepping = false)
	#await get_tree().create_timer(0.1).timeout
	#is_stepping = false
