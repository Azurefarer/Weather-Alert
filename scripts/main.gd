extends Control

var peer = ENetMultiplayerPeer.new()

@export var level: Node3D
@export var players: Node3D
@export var host_ip: TextEdit
@export var join_field: Sprite2D

@export var debug_scene: String
@export var world_scene: String

var test_scene

var external_ip

# Called when the node enters the scene tree for the first time.
func _ready():
	$BlackOverlay.self_modulate.a = 0
	port_map()
	GameManager.main = self
	GameManager.level = $Level
	GameManager.game_screen = -1
	multiplayer.connected_to_server.connect(_on_connected_ok)
	$Main_UI/BG.material.set("shader_parameter/wave_time", RippleManager.ripple_time)


func port_map():
	var upnp = UPNP.new()

	upnp.delete_port_mapping(9999,"UDP")
	upnp.delete_port_mapping(9999,"TCP")

	var discover_result = upnp.discover()

	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():

			var map_result_udp = upnp.add_port_mapping(9999,9999,"godot_udp", "UDP", 0)
			var map_result_tcp = upnp.add_port_mapping(9999,9999,"godot_tcp", "TCP", 0)

			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(9999,9999,"","UDP")
			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(9999,9999,"","TCP")

	external_ip = upnp.query_external_address()

	#upnp.delete_port_mapping(9999,"UDP")
	#upnp.delete_port_mapping(9999,"TCP")

	#$UI/PublicIP.text = str(external_ip)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_debug_pressed():
	if multiplayer.multiplayer_peer == peer or GameManager.game_mode != "menu":
		return
	GameManager.game_mode = "debug"
	await GameManager.button_feedback(GameManager.active_button)
	change_level(preload("res://assets/scenes/debug.tscn"))
	var player = preload("res://assets/prefabs/player_character.tscn").instantiate()
	print ("Spawned client player "+player.name)
	player.name = "1"
	#player.global_position = Vector3(0,600,0)
	#player.global_position = $StartingPositions.get_child(RandomNumberGenerator.new().randi_range(0,1)).global_position
	$Level/Test/Players.add_child(player)

func hide_ui():
	$Main_UI.visible = false
	$Stuff.queue_free()

func show_ui():
	$Main_UI.visible = true

func change_level(scene :PackedScene):
	await blackout()
	print("called change level")
	#for c in level.get_children():
		#level.remove_child(c)
		#c.queue_free()
	hide_ui()
	level.add_child(scene.instantiate())
	GameManager.level.add_child(preload("res://assets/scenes/world.tscn").instantiate())
	level.add_child(preload("res://assets/prefabs/time_and_weather.tscn").instantiate())


func _on_start_pressed():
	if multiplayer.multiplayer_peer == peer or GameManager.game_mode != "menu":
		return
	GameManager.game_mode = "game"
	await GameManager.button_feedback(GameManager.active_button)
	change_level.call_deferred(preload("res://assets/prefabs/ship.tscn"))

func _on_host_pressed():
	if multiplayer.multiplayer_peer == peer or GameManager.game_mode != "menu":
		return
	GameManager.game_mode = "game"
	await GameManager.button_feedback(GameManager.active_button)
	peer.create_server(9999)
	multiplayer.multiplayer_peer = peer
	change_level.call_deferred(preload("res://assets/prefabs/ship.tscn"))

func _on_join_pressed():
	join_field.visible  = !join_field.visible
	await GameManager.button_feedback(GameManager.active_button)

func _on_start_2_pressed():
	if multiplayer.multiplayer_peer == peer or GameManager.game_mode != "menu":
		return
	await GameManager.button_feedback(GameManager.active_button)
	if host_ip.text == "":
		peer.create_client("localhost",9999)
	else:
		peer.create_client(host_ip.text,9999)
	multiplayer.multiplayer_peer = peer
	#change_level("res://Assets/Scenes/World.tscn")

func _on_connected_ok():
	GameManager.game_mode = "game"
	hide_ui()

func blackout():
	while $BlackOverlay.self_modulate.a<1:
		$BlackOverlay.self_modulate.a+=GameManager.global_delta*3
		await get_tree().physics_frame

func clear_black():
	while $BlackOverlay.self_modulate.a>0:
		$BlackOverlay.self_modulate.a-=GameManager.global_delta*3
		await get_tree().physics_frame

