extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	$Scatter/grass1Scatter.enabled = true
	$Scatter/flower1Scatter.enabled = true
	$Scatter/tree2Scatter.enabled = true
	GameManager.directional_light = $DirectionalLight3D
	GameManager.stage = self
