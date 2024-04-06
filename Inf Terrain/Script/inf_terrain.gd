extends Node3D

@export var chunkSize = 400
@export var terrain_height = 20
@export var view_distance = 4000
@export var observer : Node3D
@export var chunk_mesh_scene : PackedScene

@export var noise : FastNoiseLite

var observer_position = Vector2()
var terrain_chunks = {}
var chunks_visible = 0
var last_visible_chunks = []



func _ready():
	chunks_visible = roundi(view_distance/chunkSize)
#	set_wireframe()
	updateVisibleChunk()
	
	
func set_wireframe():
	RenderingServer.set_debug_generate_wireframes(true)
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME	


func updateVisibleChunk():
	for chunk in last_visible_chunks:
		chunk.setChunkVisible(false)
	last_visible_chunks.clear()
	
	var currentX = roundi(observer_position.x/chunkSize)
	var currentY = roundi(observer_position.y/chunkSize)
	
	for yOffset in range(-chunks_visible, chunks_visible):
		for xOffset in range(-chunks_visible, chunks_visible):
			var view_chunk_coord = Vector2(currentX-xOffset, currentY-yOffset)
			if terrain_chunks.has(view_chunk_coord):
				terrain_chunks[view_chunk_coord].update_chunk(observer_position, view_distance)
				if terrain_chunks[view_chunk_coord].update_lod(observer_position):
					terrain_chunks[view_chunk_coord].terrain_gen(noise, view_chunk_coord, chunkSize, true)
				if terrain_chunks[view_chunk_coord].getChunkVisible():
					last_visible_chunks.append(terrain_chunks[view_chunk_coord])
			
			else:
				var chunk : terrainChunk = chunk_mesh_scene.instantiate()
				add_child(chunk)
				chunk.Terrain_Max_Height = terrain_height
				var pos = view_chunk_coord * chunkSize
				var world_pos = Vector3(pos.x, 0, pos.y)
				chunk.global_position = world_pos
				chunk.terrain_gen(noise, view_chunk_coord, chunkSize, false)
				terrain_chunks[view_chunk_coord] = chunk


func _process(_delta):
	observer_position.x = observer.global_position.x
	observer_position.y = observer.global_position.z
	
	updateVisibleChunk()

