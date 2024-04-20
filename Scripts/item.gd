extends RigidBody3D

@export var name_: String
var holder

func _process(delta):
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
