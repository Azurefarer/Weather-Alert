
extends RigidBody3D

@export var name_: String
var holder
@export var holder_id:= -1

@rpc("any_peer","call_local","reliable")
func update_holder_id(id):
	holder_id = id

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

func _physics_process(delta):
	if holder_id != 0:
		if holder == null:
			update_holder(holder_id)
		elif holder_id != holder.name.to_int():
			update_holder(holder_id)
	if holder:
		match name_:
			"Umbrella",\
			"FireExtinguisher":
				global_position=holder.right_hand_bone_attach.global_position+holder.get_node("RootScene/RootNode").global_basis.z*.1#+holder.get_node("RootScene/RootNode").global_basis.z*5*Vector3(holder.velocity.x,0,holder.velocity.z).length()/250
				global_position += holder.get_node("RootScene/RootNode").global_basis.x*.12
				global_rotation = holder.get_node("RootScene/RootNode").global_rotation
				rotate(Vector3.UP,115)
			"Glider":
				var targetPos =holder.right_hand_bone_attach.global_position+holder.get_node("RootScene/RootNode").global_basis.y*.3#-holder.get_node("RootScene/RootNode").global_basis.y*(holder.velocity.y/300)
				targetPos += holder.get_node("RootScene/RootNode").global_basis.x*+.3+holder.get_node("RootScene/RootNode").global_basis.z*.27#-holder.get_node("RootScene/RootNode").global_basis.z*(holder.velocity.length()/300)
				global_position = lerp(global_position,targetPos,1)
				global_rotation = holder.get_node("RootScene/RootNode").global_rotation
				#rotate(Vector3.UP,115)
