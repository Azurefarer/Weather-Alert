extends Control

var level: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.gameScreen = -1
	RippleManager.BG = $BG
	$BG.material.set("shader_parameter/wave_time", RippleManager.ripple_time)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_debug_pressed():
	await GameManager.buttonFeedback(GameManager.active_button)
	
func hide_UI():
	pass
	
func change_level(scene :String):
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	var stageToLoad = load(scene)
	var stage = stageToLoad.instantiate()
	hide_UI()
	level.add_child(stage)
	level.currentStage = stage
	
