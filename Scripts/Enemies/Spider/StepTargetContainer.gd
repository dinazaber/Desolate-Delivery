@tool
extends Node3D


@export var offset: float = 15.0

@onready var parent = get_parent()
@onready var prev_pos = parent.global_position

func _physics_process(_delta: float) -> void:
	var velocity = parent.global_position - prev_pos
	global_position = parent.global_position + velocity * offset
	
	prev_pos = parent.global_position
