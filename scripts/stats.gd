class_name Stats
extends Node

var weather_modifiers: Array
var experienced_temperature: float
var experienced_pressure: float
var experienced_humidity: float
var wind_vector: Vector3
var mass:= 70

@export var MAX_HP: int
var current_hp: int
@export var MAX_STAM: float
var current_stam: float


# Called when the node enters the scene tree for the first time.
func _ready():
	experienced_temperature = 50
	experienced_pressure = 15
	experienced_humidity = 50


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#if !is_multiplayer_authority():
	#	return
	#print("looking")

@rpc("any_peer","reliable","call_local")
func damaged(damage,blast):
	if !is_multiplayer_authority():
		return
	current_hp-=damage
	get_parent().velocity = blast
	if current_hp<0:
		die()

func die():
	current_hp = MAX_HP
	get_parent().global_position = get_parent().get_parent().global_position

func _on_update_timer_timeout():
	update()

func update():
	if !is_multiplayer_authority():
		return
	if GameManager.weather_areas.size()>0:
		wind_vector = Vector3.ZERO
		if !get_parent().ceil_check_ray.is_colliding():
			for area in GameManager.weather_areas:
				#await get_tree().physics_frame
				wind_vector+= GameManager.get_vector_from_pressure_difference(area,experienced_pressure,get_parent().global_position)
			wind_vector = wind_vector/GameManager.weather_areas.size()*3
			wind_vector.y = wind_vector.y/2
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
