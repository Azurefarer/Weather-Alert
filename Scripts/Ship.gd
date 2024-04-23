extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.ship = self
	GameManager.players = $Scalar/Players

	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	for id in multiplayer.get_peers():
		add_player(id)	
	add_player(1)#host
	
func add_player(id: int):
	var player =preload("res://Assets/Prefabs/player_character.tscn").instantiate()
	player.name = str(id)
	print ("Spawned client player "+player.name)
	#player.stats.ign = GameManager.activePlayerName
	#player.global_position = Vector3(0,600,0)
	#player.global_position = $StartingPositions.get_child(RandomNumberGenerator.new().randi_range(0,1)).global_position
	$Scalar/Players.add_child(player)
	
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

func del_player(id: int):
	if not $Players.has_node(str(id)):
		return 
	print ("deleted client player "+str(id)+"|system: "+str(multiplayer.get_unique_id()))
	$Players.get_node(str(id)).queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
