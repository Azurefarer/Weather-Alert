extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.stage = self
	$grass1Scatter.enabled = true
	$flower1Scatter.enabled = true
	$tree2Scatter.enabled = true




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
