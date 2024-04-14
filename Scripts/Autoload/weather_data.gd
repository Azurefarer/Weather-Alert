extends Node

var wind_factor : float

var weather_effects_physical : Dictionary = {
	"traction" : 1.0,
	"flooding" : 1.0,
	"visibility" : 1.0,
	"lightning" : 1.0
}

var weather_effects_mental : Dictionary = {
	"fatigue" : 1.0,
}

var colors : Dictionary = {
	"beige" : Vector3(0.8, 0.557, 0.275),
	"teal" : Vector3(0, 0.796, 0.592),
	"icy_blue" : Vector3(0.647, 0.851, 1)
}

var weather : Dictionary = {
	"rainy" : 1.0,
	"blizzard" : 1.0,
	"sandstorm" : 1.0,
}

var weather_properties : Dictionary = {
	"dryness" : 1.0,
	#"water_pressure" : 1.0,
	"pressure" : 1.0,
	"temperature" : 1.0,
	"smog" : 1.0,
}
