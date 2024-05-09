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
	# TODO: func do_umbrella_things():
