extends Control

@export var level: Node3D
@export var players: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.gameScreen = -1
	

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
	if stage.get_node("StartingPositions"):
		var starting_point = stage.get_node("StartingPositions").get_child(GameManager.rng.randi_range(0,stage.get_node("StartingPositions").get_child_count()-1))
		GameUtilities.spawn("res://Assets/Prefabs/player_character.tscn",players,starting_point.global_position,Vector3.ZERO,Vector3.ONE)
	else:
		GameUtilities.spawn("res://Assets/Prefabs/player_character.tscn",players,Vector3.ZERO,Vector3.ZERO,Vector3.ONE)
	


func _on_start_pressed():
	await GameManager.buttonFeedback(GameManager.active_button)
	change_level("res://Assets/Scenes/World.tscn")
