extends Node


func spawn(path,parent,position,rotation,scale):
	var toSpawn = load(path)
	var instance = toSpawn.instantiate()
	if parent:
		parent.add_child(instance)
		instance.position = position
		instance.rotation = rotation
		#instance.scale = scale
	else:
		get_tree().get_root().add_child(instance)
		instance.global_position = position
		instance.global_rotation = rotation
		#instance.global_scale = scale
	return instance

func spawn_player(path,parent,position,rotation,scale,id):
	var toSpawn = load(path)
	var instance = toSpawn.instantiate()
	instance.name = str(id)
	if parent:
		parent.add_child(instance)
		instance.position = position
		instance.rotation = rotation
		#instance.scale = scale
	else:
		get_tree().get_root().add_child(instance)
		instance.global_position = position
		instance.global_rotation = rotation
		#instance.global_scale = scale
	return instance
	
