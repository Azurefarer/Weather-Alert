extends Node3D

var game_time : float
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

var players : CharacterBody3D
var player_shader : ShaderMaterial

func _ready() -> void:
	var root = get_parent()
	for child in root.get_children():
		if child is CharacterBody3D:
			players = child
	player_shader = players.get_node("ScreenShader").mesh.material
	print(players)
	#get_players() # Mitch uses player node with gamer children

func _process(delta : float) -> void:
	game_time += 1.0*delta
	if game_time - floor(game_time) < 0.05:
		weather_update()
		print(str(game_time))
		
	
func weather_update():
	var indicies = $WeatherIndexTracker.calc_weather_index(players.position, game_time)
	print($WeatherIndexTracker.calc_weather_index(players.position, game_time))
	for index in weather:
		if index == "rainy":
			weather.rainy = (-cos(indicies.temperature) + 1.0) + (cos(indicies.pressure) + 1.0) + (cos(indicies.dryness) + 1.0)
		if index == "blizzard":
			weather.blizzard = (cos(indicies.temperature) + 1.0) + (-cos(indicies.pressure) + 1.0) + (sin(indicies.dryness) + 1.0)
		if index == "sandstorm":
			weather.sandstorm = (-cos(indicies.temperature) + 1.0) + (cos(indicies.pressure) + 1.0) + (cos(indicies.dryness) + 1.0)
	print(str("base weather" + str(weather)))
	
	final_weather()
	
func final_weather() -> void:
	var weatherF = weather
	var keys = []
	
	# Delete negligible weather indicies
	for index in weatherF:
		if weatherF.get(index) < 0.25:
			keys.append(weatherF.find_key(index))
	for index in weatherF:
		for entry in keys:
			if index == entry:
				weatherF.erase(index)
	print(str("Final weather" + str(weatherF)))
	# Amplify or Diminish Effects of Weather based on
	# Corresponding index.
	for index in weatherF:
		if index == "rainy":
			do_rainy_things(weatherF.get(index))
		if index == "blizzard":
			do_blizzard_things(weatherF.get(index))
		if index == "sandstorm":
			do_sandstorm_things(weatherF.get(index))
	
func do_rainy_things(amp : float):
	player_shader.set("shader_parameter/vignette_color", colors.teal)
	wind_factor = 3.0
	
	

func do_blizzard_things(amp : float):
	player_shader.set("shader_parameter/vignette_color", colors.icy_blue)


func do_sandstorm_things(amp : float):
	player_shader.set("shader_parameter/vignette_color", colors.beige)

