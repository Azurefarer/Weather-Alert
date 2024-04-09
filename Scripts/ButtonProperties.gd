extends Button

func _on_mouse_entered():
	GameManager.activeButton = self
	# Cool shader effects
	$"../BG".material.set("shader_parameter/hover", self.position)
	# Cool shader effects
	
	pass # Replace with function body.
	modulate = Color(1,1,1,1)

func _on_mouse_exited():
	# Cool shader effects
	$"../BG".material.set("shader_parameter/hover", Vector2(0.0, 0.0))
	# Cool shader effects
	pass # Replace with function body.
	modulate = Color(1,1,1,.5)
