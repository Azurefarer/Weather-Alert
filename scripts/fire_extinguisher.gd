extends Item

func update_holder_id(id):
	super.update_holder_id(id)

func update_holder(id):
	super.update_holder(id)

func _physics_process(delta):
	if holder_id != 0:
		if holder == null:
			update_holder(holder_id)
		elif holder_id != holder.name.to_int():
			update_holder(holder_id)
	if holder:
		global_position=holder.right_hand_bone_attach.global_position+holder.get_node("RootScene/RootNode").global_basis.z*.1#+holder.get_node("RootScene/RootNode").global_basis.z*5*Vector3(holder.velocity.x,0,holder.velocity.z).length()/250
		global_position += holder.get_node("RootScene/RootNode").global_basis.x*.12
		global_rotation = holder.get_node("RootScene/RootNode").global_rotation
		rotate(Vector3.UP,115)
