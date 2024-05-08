extends Node

var rng = RandomNumberGenerator.new()
var stage
var players
var global_delta: float
var game_screen =-1
var game_mode = "menu"
var level
var main
var player
var player_stats: Node
var weather_manager
var weather_areas: Array
var active_button: Button
var directional_light
var ship: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_vector_from_pressure_difference(area,experienced_pressure,current_pos):
	var total_pressure_in_area = area.pressure_psi+GameManager.weather_manager.world_pressure
	var base_directional_vector = (area.get_child(0).global_position - current_pos).normalized()
	var base_directional_length = (area.get_child(0).global_position - current_pos).length()
	var accounted_directional_vector = base_directional_vector*(4000 -clamp(base_directional_length,0,4000))
	var pressure_difference = total_pressure_in_area-experienced_pressure
	return (accounted_directional_vector)*-pressure_difference

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_delta = delta
	toggle_fullscreen()

func toggle_fullscreen():
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, 0)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, 0)

func button_feedback(button):
	button.modulate = Color(1,1,1,0)
	await get_tree().create_timer(.02).timeout
	button.modulate = Color(1,1,1,1)
	await get_tree().create_timer(.02).timeout
	button.modulate = Color(1,1,1,0)
	await get_tree().create_timer(.02).timeout
	button.modulate = Color(1,1,1,1)
	await get_tree().create_timer(.02).timeout
	button.modulate = Color(1,1,1,0)
	await get_tree().create_timer(.02).timeout
	button.modulate = Color(1,1,1,1)
	await get_tree().create_timer(.02).timeout
	button.modulate = Color(1,1,1,0)
	await get_tree().create_timer(.02).timeout
	button.modulate = Color(1,1,1,1)

func transition_camera(camera1,camera2):
	var origin_fov = camera1.fov
	camera1.fov = camera2.fov
	var origin_pos = camera1.global_position
	var origin_basis = camera1.global_basis
	camera1.global_transform = camera2.global_transform
	while(true):
		await get_tree().physics_frame
		camera1.global_position = lerp(camera1.global_position,origin_pos,GameManager.global_delta*10)
		camera1.global_basis.y = lerp(camera1.global_basis.y,origin_basis.y,GameManager.global_delta*10)
		camera1.global_basis.x = lerp(camera1.global_basis.x,-origin_basis.z.cross(Vector3(0,1,0)),GameManager.global_delta*10)
		camera1.fov = lerp(camera1.fov,origin_fov,GameManager.global_delta*10)
		#camera1.global_basis.x = lerp(camera1.global_basis.x,origin_basis.x.cross(Vector3(0,1,0)),GameManager.global_delta*4)
		camera1.global_basis = camera1.global_basis.orthonormalized()
		#camera1.global_rotation = camera1.global_rotation.slerp(originRot,GameManager.global_delta*4)
		if GameManager.player.interacting == null:
			break
	camera1.global_position = origin_pos
	camera1.global_basis = origin_basis
	camera1.fov = origin_fov

@rpc("any_peer","call_local","reliable")
func shoot(path,pos,velocity):
	var instance = load(path).instantiate()
	get_node("/root").add_child(instance)
	instance.global_position = pos
	instance.global_basis.y = velocity
	instance.linear_velocity = velocity

