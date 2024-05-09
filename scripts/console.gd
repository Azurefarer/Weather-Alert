#computer console
extends Interactable

@export var console_text : Label3D
@export var text_edit : TextEdit

@export var console_output:= "WELCOME TO STARPILOT OS\nThe ship is currently engaged in crisis protocol!\nInterfacing options are limited!\nType 'help' for a list of useful commands.\n>"
var computing = false

func item_interact():
	GameManager.weather_manager.get_node("UI").visible = false
	text_edit.grab_focus()
	while true:
		if Input.is_action_just_pressed("backout") and !computing:
			break
		if !computing:
			type()
		console_text.text = console_output+text_edit.text
		await get_tree().physics_frame
	text_edit.release_focus()
	GameManager.weather_manager.get_node("UI").visible = true
	
func type():
	if Input.is_action_just_pressed("return") and text_edit.text.replace("\n","")!="":
		analyze(text_edit.text.replace("\n",""))
		text_edit.text = ""

func analyze(text):
	if "help" in text.to_lower():	
#		console_output = "This operating system is currently under construction.\nThere are no available commands.\nGoodbye.\n--\n>"
		rpc("update_output","Results have been affected by protocol permissions!\nHOME  Return to home screen.\nPROBE  Analyze atmospheric properties.\n>")
	elif "probe" in text.to_lower():	
		computing = true
		rpc("update_output","SCANNING SURROUNDINGS")
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS."
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS.."
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS..."
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS"
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS."
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS.."
		await get_tree().create_timer(.3).timeout
		rpc("update_output","SCAN COMPLETED")
		await get_tree().create_timer(.5).timeout
		rpc("update_output","SCAN COMPLETED\nANALYZING RESULTS")
		await get_tree().create_timer(.5).timeout
		console_output = "SCAN COMPLETED\nANALYZING RESULTS."
		await get_tree().create_timer(.5).timeout
		console_output = "SCAN COMPLETED\nANALYZING RESULTS.."
		await get_tree().create_timer(.5).timeout
		console_output = "SCAN COMPLETED\nANALYZING RESULTS..."
		await get_tree().create_timer(.3).timeout
		var weather_output = "RESULTS\n\n"
		weather_output += "Planetary time is "+str(6+floor(GameManager.weather_manager.simulated_time_of_day/60)).pad_zeros(2)+":"+str(floor(fmod(GameManager.weather_manager.simulated_time_of_day,60))).pad_zeros(2)+"\n\n"
		weather_output += "Temperature of "+str(GameManager.player_stats.experienced_temperature).pad_decimals(0)+" degrees farenheit.\n"
		weather_output += "Atmospheric pressure of "+str(GameManager.player_stats.experienced_pressure).pad_decimals(0)+" PSI.\n"
		weather_output += str(GameManager.player_stats.experienced_humidity).pad_decimals(0)+" percent humidity.\n\n"
		if GameManager.weather_manager.air_quality_index>=300:
			weather_output += "WARNING! CRITICAL LEVELS OF TOXICITY!\n" 
		weather_output += "Air quality index of "+str(round(GameManager.weather_manager.air_quality_index))+"\n"
		if GameManager.weather_manager.water_quality_index<=40:
			weather_output += "WARNING! CRITICAL LEVELS OF TOXICITY!\n" 
		weather_output += "Water quality index of "+str(round(GameManager.weather_manager.water_quality_index))+"\n>"
		rpc("update_output",weather_output)
		computing = false
	else:
		rpc("update_output","ERROR CODE 127\nCommand '"+text+"' not recognized.\nType 'help' for a list of useful commands.\n>")

@rpc ("any_peer","call_local","reliable")
func update_output(output):
	console_output = output
