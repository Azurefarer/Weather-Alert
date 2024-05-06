class_name terrainChunk
extends MeshInstance3D

@export_range(20, 400, 1) var Terrain_Size := 100
@export_range(1, 100, 1) var Resolution := 30
@export var Terrain_Max_Height = 5
var chunk_lods = [5, 20, 50, 80]
var position_coord = Vector2()
const CENTER_OFFSET = 0.5

var set_collision = false


func terrain_gen(noise:FastNoiseLite, coords:Vector2, size:float, initially_visible:bool):
	Terrain_Size = size
	position_coord = coords * size
	var a_mesh : ArrayMesh
	var surftool = SurfaceTool.new()
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in Resolution+1:
		for x in Resolution+1:
			var percent = Vector2(x, z)/Resolution
			var PointOnMesh = Vector3((percent.x-CENTER_OFFSET), 0, (percent.y-CENTER_OFFSET))
			var vertex = PointOnMesh * Terrain_Size;
			vertex.y = noise.get_noise_2d(position.x + vertex.x, position.z + vertex.z) * Terrain_Max_Height
			var uv = Vector2()
			uv.x = percent.x
			uv.y = percent.y
			surftool.set_uv(uv)
			surftool.add_vertex(vertex)	
			
	var quad = 0
	for z in Resolution:
		for x in Resolution:
			surftool.add_index(quad+0)
			surftool.add_index(quad+1)
			surftool.add_index(quad+Resolution+1)
			surftool.add_index(quad+Resolution+1)
			surftool.add_index(quad+1)
			surftool.add_index(quad+Resolution+2)
			quad += 1
		quad += 1
	surftool.generate_normals()
	a_mesh = surftool.commit()
	
	mesh = a_mesh

	if set_collision == true:
		create_collision()
		
	setChunkVisible(initially_visible)
	

func update_chunk(view_pos:Vector2, max_view_dist):
	var viewer_distance = position_coord.distance_to(view_pos)
	var _is_visible = viewer_distance <= max_view_dist
	setChunkVisible(_is_visible)
	
	
func update_lod(view_pos:Vector2):
	var viewer_distance = position_coord.distance_to(view_pos)
	var update_terrain = false
	var new_lod = 0
	if viewer_distance > 1000:
		new_lod = chunk_lods[0]
	if viewer_distance <= 1000:
		new_lod = chunk_lods[1]
	if viewer_distance < 900:
		new_lod = chunk_lods[2]	
	if viewer_distance < 500:
		new_lod = chunk_lods[3]
		set_collision = true
		
	if Resolution != new_lod:
		Resolution = new_lod
		update_terrain = true
		
	return update_terrain
	
	
func setChunkVisible(_is_visible):
	visible = _is_visible
		
		
func getChunkVisible():
	return visible

		
func create_collision():
	if get_child_count() > 0:
		for i in get_children():
			i.free()
	create_trimesh_collision()

