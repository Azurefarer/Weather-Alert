extends Skeleton3D

@export var character_controller: CharacterBody3D

@export var target_skeleton: Skeleton3D
@export var skeleton_no_collision: Skeleton3D

@export var linear_spring_stiffness: float = 1500.0
@export var linear_spring_damping: float =  50.0

@export var angular_spring_stiffness: float = 400
@export var angular_spring_damping: float = 30.0

var physics_bones
# Called when the node enters the scene tree for the first time.
func _ready():
	physical_bones_start_simulation()
	physics_bones = get_children().filter(func(x): return x is PhysicalBone3D)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var root_bone = physics_bones[0]
	for b in physics_bones:
		#match b.name == 
		var target_transform: Transform3D = target_skeleton.global_transform * target_skeleton.get_bone_global_pose(b.get_bone_id())
		var target_transform_no_collide: Transform3D = skeleton_no_collision.global_transform * skeleton_no_collision.get_bone_global_pose(b.get_bone_id())
		var current_transform: Transform3D = global_transform * get_bone_global_pose(b.get_bone_id())
		var relative_position_difference: Vector3 = (skeleton_no_collision.global_transform * skeleton_no_collision.get_bone_global_pose(b.get_bone_id())).origin - (global_transform * get_bone_global_pose(b.get_bone_id())).origin
		var position_difference: Vector3 = target_transform.origin - current_transform.origin
		var force = hookes_law(position_difference, b.linear_velocity, linear_spring_stiffness, linear_spring_damping)
		b.linear_velocity += (force*delta)
		var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
		var relative_rotation_difference: Basis = (target_transform_no_collide.basis * target_transform.basis.inverse())
		var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		b.angular_velocity += (torque*delta)
		

		character_controller.velocity-=relative_position_difference*.5*character_controller.runToggle+relative_position_difference*.5
		
func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)
