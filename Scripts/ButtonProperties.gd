extends Button

func _on_mouse_entered():
	GameManager.active_button = self
	pass # Replace with function body.
	modulate = Color(1,1,1,1)

func _on_mouse_exited():
	pass # Replace with function body.
	modulate = Color(1,1,1,.5)
