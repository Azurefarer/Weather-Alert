## Works very closely with the Time_and_Weather scene and script

extends Node

const DAYS = 12
const DAY_LENGTH = 720 # Real-Time Seconds
const SIMULATED_DAY_LENGTH = 51400/60 # In-Game minutes ~ 860mins ~ 14hrs

var igmPERrs # In game minute PER real second

var weather_ui : Node
var rng = RandomNumberGenerator.new()

var current_day:= 0
var time_of_day: float
var simulated_time_of_day: float
var general_hotness: float
var general_pressure: float
var general_humidity: float
var heat_variation: float
var pressure_variation: float
var humidity_variation: float

var world_temperature
var world_humidity
var world_pressure
var weather_areas : Array

func _process(delta: float) -> void:
	while GameManager.player_stats == null:
		return
	time_of_day += delta
	simulated_time_of_day += delta * igmPERrs
	if time_of_day>720:
		initialize_day()

func initialize_day():
	current_day +=1
	time_of_day = 0
	simulated_time_of_day = 0
	general_hotness = rng.randi_range(60,70)
	general_pressure = rng.randi_range(14,20)
	general_humidity = rng.randi_range(55,75)
	heat_variation = rng.randf_range(0,1)
	pressure_variation = rng.randf_range(0,1)
	humidity_variation = rng.randf_range(0,1)

func update():
	for w in GameManager.player_stats.weather_modifiers:
		await get_tree().physics_frame
	world_temperature = general_hotness*.75+heat_variation*sin(time_of_day/10)*20+30*sin(time_of_day*PI/720)
	await get_tree().physics_frame
	world_pressure = general_pressure*.95+pressure_variation*sin(time_of_day/10)
	await get_tree().physics_frame
	world_humidity = general_humidity*.85+humidity_variation*sin(time_of_day/10)*20
	await get_tree().physics_frame
	if is_multiplayer_authority():
		weather_ui.udpate_ui()
		#$UI/Temperature.text = str(GameManager.player_stats.experienced_temperature).pad_decimals(0)+" F"
		#$UI/Pressure.text = str(GameManager.player_stats.experienced_pressure).pad_decimals(0)+" PSI"
		#$UI/Humidity.text = str(GameManager.player_stats.experienced_humidity).pad_decimals(0)+" % HUMIDITY"
		#$UI/Time.text = str(6+floor(simulated_time_of_day/60)).pad_zeros(2)+":"+str(floor(fmod(simulated_time_of_day,60))).pad_zeros(2)
		#$UI/Day.text = "Day "+str(current_day)
		#$UI/Wind.text = "[center] "+str(GameManager.player_stats.wind_vector.length()/200).pad_decimals(0)+" MPH"
	#wind_arrow.look_at(wind_arrow.global_position+GameManager.player_stats.wind_vector)
	#wind_arrow.rotate(Vector3.UP,-GameManager.player_stats.get_parent().rotation.y+180-45)

func get_vector_from_pressure_difference(area,experienced_pressure,current_pos):
	var total_pressure_in_area = area.pressure_psi+world_pressure
	var base_directional_vector = (area.get_child(0).global_position - current_pos).normalized()
	var base_directional_length = (area.get_child(0).global_position - current_pos).length()
	var accounted_directional_vector = base_directional_vector*(4000 -clamp(base_directional_length,0,4000))
	var pressure_difference = total_pressure_in_area-experienced_pressure
	return (accounted_directional_vector)*-pressure_difference
