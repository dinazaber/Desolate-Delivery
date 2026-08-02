@tool
extends EditorPlugin

const MultiMeshConverterScript = preload("res://addons/multimesh_converter/multimesh_converter.gd")
const MultiMeshConverterIcon = preload("res://addons/multimesh_converter/icon.svg")


func _enter_tree() -> void:
	add_custom_type(
		"MultiMeshConverter",
		"Node3D",
		MultiMeshConverterScript,
		MultiMeshConverterIcon
	)


func _exit_tree() -> void:
	remove_custom_type("MultiMeshConverter")
