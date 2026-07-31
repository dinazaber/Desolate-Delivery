extends Node3D


@onready var anim: AnimationPlayer = $AnimationPlayer


@export var triggerArea: Area3D
@export var toSpawn: Array[Node3D]


var is_active: bool = false

func _ready() -> void:
	if triggerArea:
		triggerArea.collision_layer = 0
		triggerArea.collision_mask = 1 << 3 # player mask
	
	toSpawn.shuffle()

func _process(delta: float) -> void:
	if is_active:
		$Skeleton3D/Lights.rotate_x(delta * PI)
		$Skeleton3D/TopPole/RadarYaw.rotate_y(-delta * PI / 4)
		
		$Skeleton3D/Bulb.get_active_material(0).emission_energy_multiplier = $Skeleton3D/Lights/SpotLight3D.light_energy

func _physics_process(_delta: float) -> void:
	# kind of a weird method, but it's simple and working
	if !triggerArea: return
	var areas = triggerArea.get_overlapping_areas()
	for area in areas:
		if area.has_method("add_trauma"): start()


func start() -> void:
	if is_active: return
	
	is_active = true
	
	anim.play("extend")
	
	for object in toSpawn:
		await get_tree().create_timer(randf_range(0.2, 0.6)).timeout
		object.start()
