extends Node3D

var observer = preload("res://Observer/observer.tscn")
var weather = preload("res://Assets/Scenes/weather.tscn")
var worms = preload("res://Assets/Scenes/box.tscn")

func _ready():
	init()
	
func _process(delta : float) -> void:
	pass

func init() -> void:
	var obsInst = observer.instantiate()
	obsInst.position.y = 20.0
	var weaInst = weather.instantiate()
	var wormsInst = worms.instantiate()
	add_child(obsInst)
	add_child(weaInst)
	add_child(wormsInst)
	obsInst.get_node("Camera3D").add_to_group("Player_Camera")

	var camList = get_tree().get_nodes_in_group("Player_Camera")
	print(camList)
	print(wormsInst.get_node("PhysicalProperties").indicies)

func _input(event):
	if event.is_action_pressed("camCycle"):
		var i : int = 0
		var camList = get_tree().get_nodes_in_group("Player_Camera")
		print(camList)
		for camera in camList:
			if camera.current:
				camera.clear_current()
				break
			i += 1
		camList[0].make_current()
				

