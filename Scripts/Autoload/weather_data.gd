extends Node

# Fundamental properties that will effect the weather
var weather : Dictionary = {
# Going to change this to be pressure
	"wind" : wind,
	"temperature" : temperature,
# Probably going to be deleted because rain is an emergent property of more fundamental weather properties (such as clouds)
# need to figure out why clouds will rain in the first place(I think they get cold enough that water molecules begin condensating)
	"precipitation" : precipitation,
	"humidity" : humidity,
# Probably going to be deleted because clouds are an emergent property of more fundamentaL weather propertie (such as pressure and humidity)
	"cloudy" : cloudy,
	
}

var wind : Dictionary = {
	"breezy" : 1.0,
	"gusty" : 1.0,
	"giga_wind" : 1.0
}

var temperature : Dictionary = {
	"freezing" : 1.0,
	"frigid" : 1.0,
	"cold" : 1.0,
	"warm" : 1.0,
	"hot" : 1.0,
	"sauna" : 1.0
}

var precipitation : Dictionary = {
	"drizzle" : 1.0,
	"rainy" : 1.0,
	"monsoon" : 1.0
}

var humidity : Dictionary = {
	"parched" : 1.0,
	"dry" : 1.0,
	"moist" : 1.0,
	"wet" : 1.0
}

var cloudy : Dictionary = {
	"clear" : 1.0,
	"partly" : 1.0,
	"heavily" : 1.0,
	"overcast" : 1.0
}

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

var weather_properties : Dictionary = {
	"dryness" : 1.0,
	#"water_pressure" : 1.0,
	"pressure" : 1.0,
	"temperature" : 1.0,
	"smog" : 1.0,
}
