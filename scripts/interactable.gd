#Interactable
extends Node3D
class_name Interactable

@export var occupied: bool
@export var stand_offset: Vector3

var camera: Camera3D
var area: Area3D

# Called when the node enters the scene tree for the first time.
func _ready():
	camera = $Camera3D
	area = $Area3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func use(user):
	if !user.fully_actionable():
		return
	#transition to interraction state
	if occupied:
		return
	rpc("update_occupied",true)
	user.interacting = self
	user.global_position = global_position+stand_offset
	user.get_node("RootScene/RootNode").look_at(Vector3(-global_position.x,user.get_node("RootScene/RootNode").global_position.y,-global_position.z))
	if camera!=null:
		GameManager.transition_camera(camera,user.camera)
		camera.current = true
		user.camera.current = false
	await get_tree().physics_frame
	#do actual interraction
	await item_interact()
	#interraction is over, reset conditions
	if camera!=null:
		camera.current = false
		user.camera.current = true
	user.interacting = null
	rpc("update_occupied",false)
	
#fill out in children classes	
func item_interact():
	while true:
		if Input.is_action_just_pressed("backout"):
			return
		await get_tree().physics_frame

@rpc("any_peer","call_local","reliable")
func update_occupied(status):
	occupied = status
