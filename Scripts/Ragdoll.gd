extends Skeleton3D


@export var target_skeleton: Skeleton3D

@export var linear_spring_stiffness: float = 2000.0
@export var linear_spring_damping: float =  40.0

@export var angular_spring_stiffness: float = 2000.0
@export var angular_spring_damping: float = 50.0

var physics_bones
# Called when the node enters the scene tree for the first time.
func _ready():
	physical_bones_start_simulation()
	physics_bones = get_children().filter(func(x): return x is PhysicalBone3D)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	for b in physics_bones:
		#match b.name == 
		var target_transform: Transform3D = target_skeleton.global_transform * target_skeleton.get_bone_global_pose(b.get_bone_id())
		var current_transform: Transform3D = global_transform * get_bone_global_pose(b.get_bone_id())
		var position_difference: Vector3 = target_transform.origin - current_transform.origin
		var force = hookes_law(position_difference, b.linear_velocity, linear_spring_stiffness, linear_spring_damping)
		b.linear_velocity += (force*delta)
		
		var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
		var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		b.angular_velocity += (torque*delta)
		
		
func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)
