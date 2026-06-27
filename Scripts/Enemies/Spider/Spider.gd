#@tool
extends Node3D


@export var move_speed: float = 2.0

@onready var skeleton: Skeleton3D = $Skeleton3D
@onready var height_check: RayCast3D = $HeightCheck

# --- IK MOVEMENT ---

@export var ground_offset: float = 1.2

@onready var ik_LFtarget: Marker3D = $IK_LFtarget
@onready var ik_LBtarget: Marker3D = $IK_LBtarget
@onready var ik_RBtarget: Marker3D = $IK_RBtarget
@onready var ik_RFtarget: Marker3D = $IK_RFtarget

var temp_basis


func _ready() -> void:
	ik_LFtarget.global_position = $StepTargetContainer/STEP_LFtarget.global_position
	ik_LBtarget.global_position = $StepTargetContainer/STEP_LBtarget.global_position
	ik_RBtarget.global_position = $StepTargetContainer/STEP_RBtarget.global_position
	ik_RFtarget.global_position = $StepTargetContainer/STEP_RFtarget.global_position
	
	temp_basis = transform.basis

func _physics_process(delta: float) -> void:
	#DEBUG_handle_movement(delta)
	
	handle_ik(delta)


func DEBUG_handle_movement(delta):
	var a_dir = Input.get_axis("A", "D")
	rotate_object_local(Vector3.UP, a_dir * 0.45 * delta)
	
	#if !a_dir:
	var dir = Input.get_axis("S", "W")
	translate(Vector3(0,0,-dir) * move_speed * delta)

func handle_ik(delta):
	#var plane1 = Plane(ik_LBtarget.global_position, ik_LFtarget.global_position, ik_RFtarget.global_position)
	#var plane2 = Plane(ik_RFtarget.global_position, ik_RBtarget.global_position, ik_LBtarget.global_position)
	
	#var avg_normal = ((plane1.normal + plane2.normal) / 2).normalized()
	
	#var target_basis = basis_from_normal(avg_normal)
	#temp_basis = lerp(temp_basis, target_basis, move_speed * delta)
	#transform.basis = temp_basis.orthonormalized()
	
	#rotation.x = clamp(rotation.x, -10.0, 10.0)
	#rotation.z = clamp(rotation.z, -10.0, 10.0)
	
	#var avg_leg_pos = (ik_LFtarget.position + ik_LBtarget.position + ik_RBtarget.position + ik_RFtarget.position) / 4
	#var target_pos = avg_leg_pos + transform.basis.y * ground_offset
	#var distance = transform.basis.y.dot(target_pos - position)
	#position = lerp(position, position + transform.basis.y * distance, 0.7 * move_speed * delta)
	
	if height_check.is_colliding():
		global_position.y = lerp(global_position.y, height_check.get_collision_point().y + ground_offset, 0.7 * move_speed * delta)

func basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	result.x = normal.cross(transform.basis.z)
	result.y = normal
	result.z = transform.basis.x.cross(normal)
	
	result = result.orthonormalized()
	result.x *= scale.x
	result.y *= scale.y
	result.z *= scale.z
	
	return result
