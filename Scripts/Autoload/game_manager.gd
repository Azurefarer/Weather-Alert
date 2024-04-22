extends Node

var rng = RandomNumberGenerator.new()
var stage
var players
var global_delta: float
var gameScreen =-1
var gameMode = "menu"
var level
var playerStats: Node
var weatherManager
var weather_areas: Array
var active_button: Button
var directional_light

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_vector_from_pressure_difference(area,experienced_pressure,currentPos):
	var totalPressureInArea = area.pressure_psi+GameManager.weatherManager.world_pressure
	var baseDirectionalVector = (area.get_child(0).global_position - currentPos).normalized()
	var baseDirectionalLength = (area.get_child(0).global_position - currentPos).length()
	var accountedDirectionalVector = baseDirectionalVector*(4000 -clamp(baseDirectionalLength,0,4000))
	var pressureDifference = totalPressureInArea-experienced_pressure
	return (accountedDirectionalVector)*-pressureDifference

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_delta = delta
	toggleFullscreen()
		
func toggleFullscreen():
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, 0)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, 0)

func buttonFeedback(button):
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
