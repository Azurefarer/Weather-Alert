#PlayerStats
extends Stats

var flags := {}
var wind_vector_mph : float
@export var fast_wind_sfx : AudioStreamPlayer
@export var breeze_sfx : AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	current_hp = MAX_HP
	if !is_multiplayer_authority():
		return
	initialize_flags()
	GameManager.player_stats = self
	while GameManager.weather_manager == null:
		await get_tree().physics_frame
	experienced_temperature = 50
	experienced_pressure = 15
	experienced_humidity = 50
	fast_wind_sfx.play()
	breeze_sfx.play()

func initialize_flags():
	flags["outside_check_morning"] = false
	flags["outside_check_afternoon"] = false
	flags["outside_check_evening"] = false

func outside_check():
	if GameManager.weather_manager.time_of_day < 250 and flags["outside_check_morning"] == false:
		SoundManager.play_sound("res://assets/sounds/melodies/day_break.mp3",-5,1,0,30)
		flags["outside_check_morning"] = true
	elif GameManager.weather_manager.time_of_day >= 250 and GameManager.weather_manager.time_of_day < 500 and flags["outside_check_afternoon"] == false:
		SoundManager.play_sound("res://assets/sounds/melodies/mid_day.mp3",-5,1,0,30)
		flags["outside_check_afternoon"] = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	environmental_sound_mixing(delta)

func environmental_sound_mixing(delta):
	if wind_vector_mph > 20:
		fast_wind_sfx.volume_db = lerp(fast_wind_sfx.volume_db,-25+wind_vector_mph/2,delta)
		fast_wind_sfx.pitch_scale = lerp(fast_wind_sfx.pitch_scale,.8+wind_vector_mph/70,delta)
	else:
		fast_wind_sfx.volume_db = lerp(fast_wind_sfx.volume_db,-80.0,delta/2)
	if wind_vector_mph >5 and wind_vector_mph <=20:
		breeze_sfx.volume_db = lerp(breeze_sfx.volume_db,-25+wind_vector_mph/2,delta)
		breeze_sfx.pitch_scale = lerp(breeze_sfx.pitch_scale,.8+wind_vector_mph/70,delta)
	else:
		fast_wind_sfx.volume_db = lerp(fast_wind_sfx.volume_db,-80.0,delta/2)
		
func _on_update_timer_timeout():
	update()

func update():
	if !is_multiplayer_authority():
		return
	if GameManager.weather_areas.size()>0:
		wind_vector = Vector3.ZERO
		if !get_parent().ceil_check_ray.is_colliding():
			if wind_vector == Vector3.ZERO:
				outside_check()
			for area in GameManager.weather_areas:
				#await get_tree().physics_frame
				wind_vector+= GameManager.get_vector_from_pressure_difference(area,experienced_pressure,get_parent().global_position)
			wind_vector = wind_vector/GameManager.weather_areas.size()*3
			wind_vector.y = wind_vector.y/2
			wind_vector_mph = wind_vector.length()/200
			await get_tree().process_frame
			#print("wind vector:"+str(wind_vector))
	var world_temperature_offset = 0
	var world_pressure_offset = 0
	var world_humidty_offset = 0
	await get_tree().process_frame
	for modifier in weather_modifiers:
		world_temperature_offset += modifier.temperature_degrees
		world_pressure_offset += modifier.pressure_psi
		world_humidty_offset += modifier.humidity
		await get_tree().process_frame
	if weather_modifiers.size()>0:
		await get_tree().process_frame
		world_temperature_offset = world_temperature_offset/weather_modifiers.size()
		await get_tree().process_frame
		world_pressure_offset = world_pressure_offset/weather_modifiers.size()
		await get_tree().process_frame
		world_humidty_offset = world_humidty_offset/weather_modifiers.size()
	await get_tree().process_frame
	experienced_temperature = lerp(experienced_temperature,GameManager.weather_manager.world_temperature+world_temperature_offset,GameManager.global_delta*10)
	await get_tree().process_frame
	experienced_pressure = lerp(experienced_pressure,GameManager.weather_manager.world_pressure+world_pressure_offset,GameManager.global_delta*3)
	await get_tree().process_frame
	experienced_humidity = lerp(experienced_humidity,GameManager.weather_manager.world_humidity+world_humidty_offset,GameManager.global_delta*3)


func _on_area_3d_body_entered(body):
	SoundManager.play_sound_3d("res://assets/sounds/sfx/player/footstep"+str(GameManager.rng.randi_range(1,3))+".mp3",-12,1,.2,3,20,get_parent().global_position)
