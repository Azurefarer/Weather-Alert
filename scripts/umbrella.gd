extends Item

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
	# TODO: func do_umbrella_things():
