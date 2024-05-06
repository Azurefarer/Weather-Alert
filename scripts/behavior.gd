extends Node

@export var nav: NavigationAgent3D
@export var nav_check_ray: RayCast3D
@export var head: BoneAttachment3D
@export var shoot_timer: Timer
var origin: Vector3
var current_behavior: String = "wander"

# Called when the node enters the scene tree for the first time.
func _ready():
	origin = get_parent().global_position

func wander():
	current_behavior = "wander"
	nav_check_ray.position.x = GameManager.rng.randi_range(-250,250)
	nav_check_ray.position.z = GameManager.rng.randi_range(-250,250)
	if nav_check_ray.is_colliding():
		nav.target_position = nav_check_ray.get_collision_point()
		#print("wander update:"+str(nav.target_position))
	#nav.target_position = origin + Vector3(GameManager.rng.randi_range(-250,250),origin.y,GameManager.rng.randi_range(-250,250))
	
func watch():
	if current_behavior == "watch":
		return
	shoot_timer.start(0.5)
	current_behavior = "watch"
	#print("watch start")
	nav.target_position = get_parent().global_position
	while current_behavior == "watch":
		get_parent().look_at(Vector3(get_parent().watching.global_position.x,get_parent().global_position.y,get_parent().watching.global_position.z))
		get_parent().rotate(Vector3.UP,PI)
		head.look_at(get_parent().watching.global_position)
		head.rotate(head.basis.x.normalized(),-.85*PI)
		#head.rotate(Vector3.UP,PI)
		await  get_tree().physics_frame
		
func _on_timer_timeout():
	if !is_multiplayer_authority():
		return
	determine_behavior()
	
func determine_behavior():
	if get_parent().target == null:
		wander()
	else:
		watch()
