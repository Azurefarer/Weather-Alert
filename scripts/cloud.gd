#Cloud
extends Stats

var velocity: Vector3
@export var dropEmitter: GPUParticles3D
@export var cloudEmitter: GPUParticles3D

# Called when the node enters the scene tree for the first time.
func _ready():
	experienced_temperature = 50
	experienced_pressure = 15
	experienced_humidity = 50


func _process(delta):
	velocity= velocity.lerp(wind_vector,delta/5)
	#print("velocity:"+str(velocity))
	get_parent().global_position += velocity*delta/30		

func _on_update_timer_timeout():
	update()

func update():
	if experienced_humidity>=60:
		dropEmitter.emitting = true
	else:
		dropEmitter.emitting = false
	if !is_multiplayer_authority():
		return
	if GameManager.weather_areas.size()>0:
		wind_vector = Vector3.ZERO
		if true:
			for area in GameManager.weather_areas:
				#await get_tree().physics_frame
				wind_vector+= GameManager.get_vector_from_pressure_difference(area,experienced_pressure,get_parent().global_position)
			wind_vector = wind_vector/GameManager.weather_areas.size()*3
			wind_vector.y = wind_vector.y/2
			#print(wind_vector)
			await get_tree().process_frame
			#print("wind vector:"+str(wind_vector))
	var worldTemperatureOffset = 0
	var worldPressureOffset = 0
	var worldHumidityOffset = 0
	await get_tree().process_frame
	for modifier in weather_modifiers:
		worldTemperatureOffset += modifier.temperature_degrees
		worldPressureOffset += modifier.pressure_psi
		worldHumidityOffset += modifier.humidity
		await get_tree().process_frame
	if weather_modifiers.size()>0:
		await get_tree().process_frame
		worldTemperatureOffset = worldTemperatureOffset/weather_modifiers.size()
		await get_tree().process_frame
		worldPressureOffset = worldPressureOffset/weather_modifiers.size()
		await get_tree().process_frame
		worldHumidityOffset = worldHumidityOffset/weather_modifiers.size()
	await get_tree().process_frame
	experienced_temperature = lerp(experienced_temperature,GameManager.weatherManager.world_temperature+worldTemperatureOffset,GameManager.global_delta*10)
	await get_tree().process_frame
	experienced_pressure = lerp(experienced_pressure,GameManager.weatherManager.world_pressure+worldPressureOffset,GameManager.global_delta*3)
	await get_tree().process_frame
	experienced_humidity = lerp(experienced_humidity,GameManager.weatherManager.world_humidity+worldHumidityOffset,GameManager.global_delta*3)


func _on_reposition_timer_timeout():
	get_parent().global_position.x = GameManager.rng.randi_range(-2500,2500)
	get_parent().global_position.y = GameManager.rng.randi_range(-2500,2500)
