extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	$grass1Scatter.enabled = true
	$flower1Scatter.enabled = true
	$tree2Scatter.enabled = true
	GameManager.stage = self
