@tool
extends Path3D

@export var fence_mesh: Mesh:
	set(value):
		fence_mesh = value
		generate_fence()

@export var spacing: float = 4.0:
	set(value):
		spacing = value
		generate_fence()

func _ready():
	if not curve_changed.is_connected(generate_fence):
		curve_changed.connect(generate_fence)
	generate_fence()

func generate_fence():
	if not is_inside_tree() or fence_mesh == null:
		return

	for child in get_children():
		if child.name == "GeneratedFence":
			child.free()

	var length = curve.get_baked_length()
	if length == 0: return
	
	var count = floor(length / spacing) + 1
	
	var mm_inst = MultiMeshInstance3D.new()
	mm_inst.name = "GeneratedFence"
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = fence_mesh
	mm.instance_count = count
	
	for i in range(count):
		var curve_offset = i * spacing
		
		# Wrap the offset so the last post sits perfectly on the start/end point
		if curve_offset > length:
			curve_offset = length
			
		var pos = curve.sample_baked(curve_offset)
		var next_pos = curve.sample_baked(curve_offset + 0.1)
		
		if pos.is_equal_approx(next_pos):
			next_pos = curve.sample_baked(curve_offset - 0.1)
			
		var b = Basis.looking_at(next_pos - pos, Vector3.UP)
		var t = Transform3D(b, pos)
		mm.set_instance_transform(i, t)
	
	mm_inst.multimesh = mm
	add_child(mm_inst)
	
	if Engine.is_editor_hint():
		mm_inst.owner = get_tree().edited_scene_root
