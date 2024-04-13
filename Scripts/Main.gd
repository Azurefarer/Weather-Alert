extends Control

@export var level: Node3D
@export var players: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.gameScreen = -1
	RippleManager.BG = $Main_UI/BG
	$Main_UI/BG.material.set("shader_parameter/wave_time", RippleManager.ripple_time)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_debug_pressed():
	await GameManager.buttonFeedback(GameManager.active_button)
	change_level("res://Assets/Scenes/Test.tscn")
	
func hide_UI():
	$Main_UI.visible = false
	
func show_UI():
	$Main_UI.visible = true
	
func change_level(scene :String):
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	var stageToLoad = load(scene)
	var stage = stageToLoad.instantiate()
	hide_UI()
	level.add_child(stage)
	GameUtilities.spawn("res://Assets/Prefabs/player_character.tscn",players,Vector3.ZERO,Vector3.ZERO,Vector3.ONE)
	
