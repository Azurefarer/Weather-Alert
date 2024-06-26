extends Button

@onready var BG : TextureRect = $"../BG"
@onready var main : Control = get_node("/root/main")


func _on_mouse_entered():
	GameManager.active_button = self
	RippleManager.inst_ripple(get_global_mouse_position())

	modulate = Color(1,1,1,1)

func _on_mouse_exited():
	modulate = Color(1,1,1,.5)

func _on_pressed() -> void:
	RippleManager.inst_ripple_click(get_global_mouse_position())
