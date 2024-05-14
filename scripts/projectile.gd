extends RigidBody3D

@export var damage: int
@export var lifetime: float
@export var knockback: int
var time := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time+=delta
	if time>lifetime:
		queue_free()

#projectile hits something
func _on_body_entered(body):
	if !is_multiplayer_authority():
		queue_free()
		return
	if body is PlayerCharacter:
		body.stats.rpc("damaged",damage,global_basis.z*knockback)
		#print("hit player")
	elif body is PhysicalBone3D:
		#print("hit player")
		body.get_parent().get_parent().get_parent().get_parent().get_parent().stats.rpc("damaged",(body.global_position-global_position).normalized()*knockback)
	queue_free()
