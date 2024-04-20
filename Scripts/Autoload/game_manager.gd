extends Node

var rng = RandomNumberGenerator.new()

var global_delta: float
var gameScreen =-1

var active_button: Button

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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
