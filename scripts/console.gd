#computer console
extends Interactable

@export var console_output:= "WELCOME TO  edmOS\n####################################################\nPlease type 'help' to querry a list of commands.\n--\n>"
var computing = false

func item_interact():
	GameManager.weather_manager.get_node("UI").visible = false
	$Monitor/TextEdit.grab_focus()
	while true:
		if Input.is_action_just_pressed("backout") and !computing:
			break
		if !computing:
			type()
		$Monitor/ConsoleText.text = console_output+$Monitor/TextEdit.text
		await get_tree().physics_frame
	$Monitor/TextEdit.release_focus()
	GameManager.weather_manager.get_node("UI").visible = true
	
func type():
	if Input.is_action_just_pressed("return") and $Monitor/TextEdit.text.replace("\n","")!="":
		analyze($Monitor/TextEdit.text.replace("\n",""))
		$Monitor/TextEdit.text = ""

func analyze(text):
	if "help" in text.to_lower():	
#		console_output = "This operating system is currently under construction.\nThere are no available commands.\nGoodbye.\n--\n>"
		rpc("update_output","NAVIGATE - Route the ship to a new location.\nWEATHER - Analyze atmospheric properties.\n--\n>")
	elif "weather" in text.to_lower():	
		computing = true
		rpc("update_output","SCANNING SURROUNDINGS")
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS."
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS.."
		await get_tree().create_timer(.5).timeout
		console_output = "SCANNING SURROUNDINGS..."
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
		await get_tree().create_timer(.3).timeout
		var weather_output = "IMMEDIATE WEATHER FINDINGS:\n"
		weather_output += "Planetary time is "+str(6+floor(GameManager.weather_manager.simulated_time_of_day/60)).pad_zeros(2)+":"+str(floor(fmod(GameManager.weather_manager.simulated_time_of_day,60))).pad_zeros(2)+"\n"
		weather_output += "Temperature of "+str(GameManager.player_stats.experienced_temperature).pad_decimals(0)+" degrees farenheit.\n"
		weather_output += "Atmospheric pressure of "+str(GameManager.player_stats.experienced_pressure).pad_decimals(0)+" PSI.\n"
		weather_output += str(GameManager.player_stats.experienced_humidity).pad_decimals(0)+" percent humidity.\n--\n>"
		rpc("update_output",weather_output)
		computing = false
	else:
		rpc("update_output","ERROR CODE 127\nCommand '"+text+"' not recognized.\nPlease type 'help' to querry a list of commands.\n--\n>")

@rpc ("any_peer","call_local","reliable")
func update_output(output):
	console_output = output
