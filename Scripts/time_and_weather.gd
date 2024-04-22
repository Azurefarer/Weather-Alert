extends Node

const DAYS = 12
const DAY_LENGTH = 720
const SIMULATED_DAY_LENGTH = 51400/60

var igmPERrs
var rng = RandomNumberGenerator.new()
@export var current_day:= 0
@export var time_of_day: float
@export var simulated_time_of_day: float
@export var general_hotness: float
@export var general_pressure: float
@export var general_humidity: float
@export var heat_variation: float
@export var pressure_variation: float
@export var humidity_variation: float
@export var world_temperature: float
@export var world_pressure: float
@export var world_humidity: float
@export var wind_arrow_camera: Camera3D
@export var wind_arrow: Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.weatherManager = self
	while GameManager.playerStats == null:
		await get_tree().physics_frame
	update()
	if is_multiplayer_authority():
		initialize_day()
		igmPERrs = float(SIMULATED_DAY_LENGTH)/float(DAY_LENGTH)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	while GameManager.playerStats == null:
		return
	if is_multiplayer_authority():
		GameManager.directional_light.rotation.x = lerp(GameManager.directional_light.rotation.x,deg_to_rad(200+(time_of_day/720)*180),delta)
		if GameManager.playerStats.wind_vector == Vector3.ZERO:
			$WeatherArrow.modulate.a = lerp($WeatherArrow.modulate.a,0.0,delta*10)
			$Wind.modulate.a = lerp($Wind.modulate.a,0.0,delta*10)
		else:
			$WeatherArrow.modulate.a = lerp($WeatherArrow.modulate.a,1.0,delta*10)
			$Wind.modulate.a = lerp($Wind.modulate.a,1.0,delta*10)
			wind_arrow.look_at(wind_arrow.global_position+GameManager.playerStats.wind_vector)
			wind_arrow.rotate(Vector3.UP,-GameManager.playerStats.get_parent().rotation.y+180-45)
		time_of_day+=delta
		simulated_time_of_day+=delta*igmPERrs
		if time_of_day>720:
			initialize_day()
	
	if GameManager.playerStats == null:
		return
	
func initialize_day():
	current_day +=1
	time_of_day = 0
	simulated_time_of_day = 0
	general_hotness = rng.randi_range(60,70)
	general_pressure = rng.randi_range(14,20)
	general_humidity = rng.randi_range(55,75)
	var heat_variation = rng.randf_range(0,1)
	var pressure_variation = rng.randf_range(0,1)
	var humidity_variation = rng.randf_range(0,1)


func _on_update_timer_timeout():
	update()

func update():
	for w in GameManager.playerStats.weather_modifiers:
		await get_tree().physics_frame
	world_temperature =  general_hotness*.75+heat_variation*sin(time_of_day/10)*20+30*sin(time_of_day*PI/720)
	await get_tree().physics_frame
	world_pressure =  general_pressure*.95+pressure_variation*sin(time_of_day/10)
	await get_tree().physics_frame
	world_humidity =  general_humidity*.85+humidity_variation*sin(time_of_day/10)*20
	await get_tree().physics_frame
	if is_multiplayer_authority():
		$Temperature.text = str(GameManager.playerStats.experienced_temperature).pad_decimals(0)+" F"
		$Pressure.text = str(GameManager.playerStats.experienced_pressure).pad_decimals(0)+" PSI"
		$Humidity.text = str(GameManager.playerStats.experienced_humidity).pad_decimals(0)+" %HUMIDITY"
		$Time.text = str(6+floor(simulated_time_of_day/60)).pad_zeros(2)+":"+str(floor(fmod(simulated_time_of_day,60))).pad_zeros(2)
		$Day.text = "Day "+str(current_day)
		$Wind.text = "[center] "+str(GameManager.playerStats.wind_vector.length()/200).pad_decimals(0)+" MPH"
	#wind_arrow.look_at(wind_arrow.global_position+GameManager.playerStats.wind_vector)
	#wind_arrow.rotate(Vector3.UP,-GameManager.playerStats.get_parent().rotation.y+180-45)

func _on_weather_event_timeout():
	pass # Replace with function body.
