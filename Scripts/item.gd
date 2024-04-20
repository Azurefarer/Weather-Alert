extends RigidBody3D

@export var name_: String
var holder
@export var holderID:= -1

@rpc("any_peer","call_local","reliable")
func update_holder_id(id):
	holderID = id

func update_holder(id):
	holder = null
	for player in GameManager.players.get_children(): 
		if player.name.to_int() == id:
			holder = player
			holder.holding_item = self
	if id != -1:
		freeze = true
		collision_layer = 16
	else:
		freeze = false
		collision_layer = 17

func _process(delta):
	if holderID != 0:
		if holder == null:
			update_holder(holderID)
		elif holderID != holder.name.to_int():
			update_holder(holderID)
	if holder:
		match name_:
			"FireExtinguisher":
				global_position=holder.rightHandPhysicsBone.global_position+holder.get_node("RootScene/RootNode").global_basis.z*.1+holder.get_node("RootScene/RootNode").global_basis.z*5*Vector3(holder.velocity.x,0,holder.velocity.z).length()/250
				global_position += holder.get_node("RootScene/RootNode").global_basis.x*.12
				global_rotation = holder.get_node("RootScene/RootNode").global_rotation
				rotate(Vector3.UP,115)
			"Glider":
				global_position=holder.rightHandPhysicsBone.global_position+holder.get_node("RootScene/RootNode").global_basis.z*.3+holder.get_node("RootScene/RootNode").global_basis.z*5*Vector3(holder.velocity.x,0,holder.velocity.z).length()/350
				global_position += holder.get_node("RootScene/RootNode").global_basis.x*.275+holder.get_node("RootScene/RootNode").global_basis.y*.43-holder.get_node("RootScene/RootNode").global_basis.y*-(holder.flightAngle-1.4)/10
				global_rotation = holder.get_node("RootScene/RootNode").global_rotation
				#rotate(Vector3.UP,115)
