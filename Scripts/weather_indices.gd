extends Node

var indicies : Dictionary = {
	"dryness" : 1.0,
	#"water_pressure" : 1.0,
	"pressure" : 1.0,
	"temperature" : 1.0,
	"smog" : 1.0,
}


func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	pass
	

func calc_weather_index(pos : Vector3, game_time : float) -> Dictionary:
	# these need to be equations that take in pos and time as varibales
	# and spit out the desired weather index
	# Still looking into a sufficient eqn to use here
		indicies.temperature = sqrt(pos.dot(pos))*sin(game_time)
		indicies.pressure = sqrt(pos.dot(pos))*sin(game_time)
		indicies.dryness = sqrt(pos.dot(pos))*sin(game_time)
		
		return indicies
		


