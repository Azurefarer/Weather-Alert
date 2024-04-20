extends Control

var peer = ENetMultiplayerPeer.new()

@export var level: Node3D
@export var players: Node3D
@export var hostIP: TextEdit
@export var joinField: Sprite2D
var external_ip

# Called when the node enters the scene tree for the first time.
func _ready():
	portMap()
	GameManager.gameScreen = -1
	multiplayer.connected_to_server.connect(_on_connected_ok)
	
func portMap():
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
	await GameManager.buttonFeedback(GameManager.active_button)
	add_player(1)
	change_level("res://Assets/Scenes/Test.tscn")
	
func hide_UI():
	$Main_UI.visible = false
	
func show_UI():
	$Main_UI.visible = true
	
func change_level(scene :String):
	print("called change level")
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	var stageToLoad = load(scene)
	var stage = stageToLoad.instantiate()
	hide_UI()
	level.add_child(stage)

@rpc("any_peer", "call_local", "reliable") 	
func add_player(id: int):
	if !is_multiplayer_authority():
		return
	print("called add player")
	var player
	while !GameManager.stage:
		await get_tree().process_frame
	var starting_point = GameManager.stage.get_node("StartingPositions").get_child(GameManager.rng.randi_range(0,GameManager.stage.get_node("StartingPositions").get_child_count()-1))
	player = GameUtilities.spawn_player("res://Assets/Prefabs/player_character.tscn",players,starting_point.global_position,Vector3.ZERO,Vector3.ONE,id)
	#print("udpdated player name to id")

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local") 
func _del_player(id):
	get_node(str(id)).queue_free()

func _on_start_pressed():
	await GameManager.buttonFeedback(GameManager.active_button)
	add_player(1)
	change_level("res://Assets/Scenes/World.tscn")

func _on_host_pressed():
	await GameManager.buttonFeedback(GameManager.active_button)
	peer.create_server(9999)
	multiplayer.multiplayer_peer = peer
	add_player(1)
	change_level("res://Assets/Scenes/World.tscn")

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func _on_join_pressed():
	joinField.visible  = !joinField.visible
	await GameManager.buttonFeedback(GameManager.active_button)


func _on_start_2_pressed():
	await GameManager.buttonFeedback(GameManager.active_button)
	if hostIP.text == "":
		peer.create_client("localhost",9999)
	else:
		peer.create_client(hostIP.text,9999)
	multiplayer.multiplayer_peer = peer
	
func _on_connected_ok():
	print("client UID: "+str(multiplayer.get_unique_id()))
	#rpc("add_player",multiplayer.get_unique_id())
	add_player(multiplayer.get_unique_id())
	change_level("res://Assets/Scenes/World.tscn")
	#_add_player(peer.generate_unique_id())
	hide_UI()

