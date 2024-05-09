class_name Item extends RigidBody3D

@export var name_: String
var holder : CharacterBody3D
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
