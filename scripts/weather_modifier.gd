extends Area3D

@export var temperature_degrees: float
@export var pressure_psi: float
@export var humidity: float

# Called when the node enters the scene tree for the first time.
func _ready():
	WeatherManager.weather_areas.append(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_body_entered(body):
	body.get_node("Stats").weather_modifiers.append(self)

func _on_body_exited(body):
	body.get_node("Stats").weather_modifiers.erase(self)

func _on_area_entered(area):#cloud entering or other weather entity
	area.get_node("Stats").weather_modifiers.append(self)

func _on_area_exited(area):
	area.get_node("Stats").weather_modifiers.erase(self)
