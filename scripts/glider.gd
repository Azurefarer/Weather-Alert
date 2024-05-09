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
		print(str(holder))
		var targetPos =holder.right_hand_bone_attach.global_position+holder.get_node("RootScene/RootNode").global_basis.y*.3#-holder.get_node("RootScene/RootNode").global_basis.y*(holder.velocity.y/300)
		targetPos += holder.get_node("RootScene/RootNode").global_basis.x*+.3+holder.get_node("RootScene/RootNode").global_basis.z*.27#-holder.get_node("RootScene/RootNode").global_basis.z*(holder.velocity.length()/300)
		global_position = lerp(global_position,targetPos,1)
		global_rotation = holder.get_node("RootScene/RootNode").global_rotation
		#rotate(Vector3.UP,115)
