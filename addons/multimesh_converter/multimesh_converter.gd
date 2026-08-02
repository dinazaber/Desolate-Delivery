@tool
extends Node3D

## The Mesh that the generated MultiMesh will use.
## This is applied uniformly to every instance in the result, so children
## don't need to already have this mesh assigned - their own mesh (if any)
## is only used for editor preview and is never changed.
@export var mesh: Mesh:
	set(value):
		mesh = value
		update_configuration_warnings()

## Name given to the generated MultiMeshInstance3D child.
const RESULT_NAME := "Result"

@export_tool_button("Create Multimesh", "MultiMeshInstance3D")
var create_multimesh_action: Callable = create_multimesh


func create_multimesh() -> void:
	if mesh == null:
		push_warning("MultiMeshConverter: Assign a Mesh in the inspector before creating the MultiMesh.")
		return

	# Gather transforms from every valid child, skipping only a previous
	# "Result" node (if one exists) and any non-Node3D children (which have
	# no transform to contribute).
	var transforms: Array[Transform3D] = []
	for child in get_children():
		if child.name == RESULT_NAME:
			continue
		if child is Node3D:
			transforms.append(child.transform)
		else:
			push_warning("MultiMeshConverter: Skipping child '%s' - not a Node3D, has no transform." % child.name)

	if transforms.is_empty():
		push_warning("MultiMeshConverter: No valid Node3D children found under this node.")
		return

	# Remove any previously generated result so re-running the button is safe.
	var old_result := get_node_or_null(RESULT_NAME)
	if old_result:
		remove_child(old_result)
		old_result.free()

	# Average origin of all children, used so the Result node sits in the
	# "middle" of its instances instead of at MultiMeshConverter's origin.
	var average_origin := Vector3.ZERO
	for t in transforms:
		average_origin += t.origin
	average_origin /= transforms.size()

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()

	for i in transforms.size():
		var instance_transform := transforms[i]
		instance_transform.origin -= average_origin
		mm.set_instance_transform(i, instance_transform)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = RESULT_NAME
	mmi.multimesh = mm
	mmi.position = average_origin

	add_child(mmi)

	# Give it an owner so it gets saved with the scene when running in the editor.
	if Engine.is_editor_hint():
		var edited_root := get_tree().edited_scene_root if get_tree() else null
		mmi.owner = edited_root if edited_root else self

	print("MultiMeshConverter: Created '%s' with %d instance(s) using mesh '%s'." % [
		RESULT_NAME, transforms.size(), mesh.resource_path if mesh.resource_path != "" else mesh.get_class()
	])


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if mesh == null:
		warnings.append("No Mesh assigned. Assign a Mesh - it will be used for every instance in the generated MultiMesh.")

	var has_valid_child := false
	for child in get_children():
		if child.name != RESULT_NAME and child is Node3D:
			has_valid_child = true
			break
	if not has_valid_child:
		warnings.append("No Node3D children found. Add child nodes whose transforms should become MultiMesh instances.")

	return warnings
