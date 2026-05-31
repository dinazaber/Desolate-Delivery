@tool
extends EditorPlugin

func _enter_tree():
	add_tool_menu_item("Merge Identical Meshes (1 Material)", _merge_selected)

func _exit_tree():
	remove_tool_menu_item("Merge Identical Meshes (1 Material)")

func _merge_selected():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	var mesh_instances: Array[MeshInstance3D] = []
	
	for node in selection:
		if node is MeshInstance3D and node.mesh:
			mesh_instances.append(node)
			
	if mesh_instances.size() < 1:
		printerr("Select at least one MeshInstance3D")
		return

	var target_material = mesh_instances[0].get_active_material(0)
	var source_mesh = mesh_instances[0].mesh
	
	# Get the array format from the first mesh to ensure we match it exactly
	# This includes information about how CUSTOM0/1 are stored
	var combined_arrays = []
	combined_arrays.resize(Mesh.ARRAY_MAX)
	
	var final_verts = PackedVector3Array()
	var final_norms = PackedVector3Array()
	var final_uvs = PackedVector2Array()
	var final_uvs2 = PackedVector2Array()
	var final_colors = PackedColorArray()
	var final_custom0 = PackedFloat32Array()
	var final_custom1 = PackedFloat32Array()
	var final_indices = PackedInt32Array()
	
	var vertex_offset = 0
	var mesh_count = mesh_instances.size()
	var grid_size = ceil(sqrt(mesh_count))
	
	for i in range(mesh_count):
		var mi = mesh_instances[i]
		var xform = mi.global_transform
		# Get arrays from surface 0
		var arrays = mi.mesh.surface_get_arrays(0)
		
		var src_verts = arrays[Mesh.ARRAY_VERTEX]
		var src_indices = arrays[Mesh.ARRAY_INDEX]
		var src_uv2s = arrays[Mesh.ARRAY_TEX_UV2]
		
		var row = i / int(grid_size)
		var col = i % int(grid_size)
		
		var uv2_padding = 0.05
		var uv2_scale = (1.0 / grid_size)
		var uv2_offset = Vector2(col * uv2_scale, row * uv2_scale)
		uv2_scale = (1.0 / grid_size) * (1 - uv2_padding)
		# 1. Transform Vertices
		for v in src_verts:
			final_verts.append(xform * v)
		
		
		for uv in src_uv2s:
			final_uvs2.append((uv * uv2_scale) + uv2_offset)
			
		# 2. Transform Normals (Basis only)
		if arrays[Mesh.ARRAY_NORMAL]:
			var basis = xform.basis.inverse().transposed()
			for n in arrays[Mesh.ARRAY_NORMAL]:
				final_norms.append((basis * n).normalized())
		
		# 3. Direct Append for simple data
		if arrays[Mesh.ARRAY_TEX_UV]:
			final_uvs.append_array(arrays[Mesh.ARRAY_TEX_UV])
		if arrays[Mesh.ARRAY_COLOR]:
			final_colors.append_array(arrays[Mesh.ARRAY_COLOR])
			
		# 4. Copy Custom Data
		if arrays[Mesh.ARRAY_CUSTOM0]:
			final_custom0.append_array(arrays[Mesh.ARRAY_CUSTOM0])
		if arrays[Mesh.ARRAY_CUSTOM1]:
			final_custom1.append_array(arrays[Mesh.ARRAY_CUSTOM1])
			
		# 5. Offset Indices
		if src_indices:
			for idx in src_indices:
				final_indices.append(idx + vertex_offset)
		
		vertex_offset += src_verts.size()

	# Assign to master array
	combined_arrays[Mesh.ARRAY_VERTEX] = final_verts
	combined_arrays[Mesh.ARRAY_NORMAL] = final_norms
	combined_arrays[Mesh.ARRAY_TEX_UV] = final_uvs
	combined_arrays[Mesh.ARRAY_TEX_UV2] = final_uvs2
	combined_arrays[Mesh.ARRAY_COLOR] = final_colors
	combined_arrays[Mesh.ARRAY_INDEX] = final_indices
	
	# Only include custom arrays if they actually contain data
	if final_custom0.size() > 0:
		combined_arrays[Mesh.ARRAY_CUSTOM0] = final_custom0
	if final_custom1.size() > 0:
		combined_arrays[Mesh.ARRAY_CUSTOM1] = final_custom1
	
	var h_mesh = ArrayMesh.new()
	
	# CRITICAL: We use the format flags from the original mesh surface
	# This tells Godot if CUSTOM0 is a Vector4, Vector2, etc.
	var format_flags = source_mesh.surface_get_format(0)
	h_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, combined_arrays, [], {}, format_flags)
	h_mesh.surface_set_material(0, target_material)
	
	
	var combined_node = MeshInstance3D.new()
	combined_node.mesh = h_mesh
	combined_node.name = "Merged_" + mesh_instances[0].name
	
	var root = EditorInterface.get_edited_scene_root()
	root.add_child(combined_node)
	combined_node.owner = root
	combined_node.global_transform = Transform3D.IDENTITY
	
	print("Success: Merged into surface with format flags: ", format_flags)
