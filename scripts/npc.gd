class_name NPC
extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5  

@export var velocity_export: Vector3
@export var animation_player: AnimationPlayer
@export var current_animation: String
@export var ceil_check_ray: RayCast3D
@export var nav: NavigationAgent3D
@onready var stats: Node = $Stats
var direction: Vector3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func look_at_target(delta):
	var original_rotation = global_rotation
	var look_to = (global_position-direction.normalized()*100)
	look_to.y = global_position.y
	if (look_to - global_position).length() > 1:
		look_at(look_to)
	var target_rotation = global_rotation
	global_rotation = original_rotation
	global_rotation.y = lerp_angle(global_rotation.y,target_rotation.y,delta*1)
	global_rotation.x = lerp_angle(global_rotation.x,target_rotation.x,delta*1)
	global_rotation.z = lerp_angle(global_rotation.z,0,delta*14)

func _physics_process(delta):
	navigation_path(delta)
	animate()
	if !is_multiplayer_authority():
		return
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		apply_floor_snap()
	velocity_export = velocity
	move_and_slide()

func navigation_path(delta):
	var direction = Vector3()
	direction = nav.get_next_path_position() - global_position
	direction = direction.normalized()
	velocity = velocity.lerp(direction*SPEED,delta*3)
	var original_rotation = global_rotation
	var look_to = (global_position-direction.normalized()*100)
	look_to.y = global_position.y
	look_at(look_to)
	var target_rotation = global_rotation
	global_rotation = original_rotation
	global_rotation.y = lerp_angle(global_rotation.y,target_rotation.y,delta*1)
	global_rotation.x = lerp_angle(global_rotation.x,target_rotation.x,delta*1)
	global_rotation.z = lerp_angle(global_rotation.z,0,delta*14)

func animate():
	if is_on_floor():
		if velocity_export.length()>1:
			animation_player.play("walk",.1)
			animation_player.speed_scale = velocity_export.length()/5
		else:
			animation_player.play("idle",.1)
			animation_player.speed_scale = 1
