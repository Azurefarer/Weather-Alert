extends Node

var game_time : float

var players : CharacterBody3D
var player_shader : ShaderMaterial

var weather_props : Dictionary

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
	for index in WeatherData.weather:
		if index == "rainy":
			WeatherData.weather.rainy = (-cos(WeatherData.indicies.temperature) + 1.0) + (cos(WeatherData.indicies.pressure) + 1.0) + (cos(WeatherData.indicies.dryness) + 1.0)
		if index == "blizzard":
			WeatherData.weather.blizzard = (cos(WeatherData.indicies.temperature) + 1.0) + (-cos(WeatherData.indicies.pressure) + 1.0) + (sin(WeatherData.indicies.dryness) + 1.0)
		if index == "sandstorm":
			WeatherData.weather.sandstorm = (-cos(WeatherData.indicies.temperature) + 1.0) + (cos(WeatherData.indicies.pressure) + 1.0) + (cos(WeatherData.indicies.dryness) + 1.0)
	print(str("base weather" + str(WeatherData.weather)))
	
	final_weather()
	
func final_weather() -> void:
	var weatherF = WeatherData.weather
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
	player_shader.set("shader_parameter/vignette_color", WeatherData.colors.teal)

func do_blizzard_things(amp : float):
	player_shader.set("shader_parameter/vignette_color", WeatherData.colors.icy_blue)

func do_sandstorm_things(amp : float):
	player_shader.set("shader_parameter/vignette_color", WeatherData.colors.beige)

func calc_weather_index(pos : Vector3, game_time : float) -> Dictionary:
	# these need to be equations that take in pos and time as varibales
	# and spit out the desired weather index
	# Still looking into a sufficient eqn to use here
		WeatherData.indicies.temperature = sqrt(pos.dot(pos))*sin(game_time)
		WeatherData.indicies.pressure = sqrt(pos.dot(pos))*sin(game_time)
		WeatherData.indicies.dryness = sqrt(pos.dot(pos))*sin(game_time)
		
		return WeatherData.indicies
		



