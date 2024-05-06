@tool
extends MeshInstance3D

@export_range(20, 400, 1) var Terrain_Size := 100
@export_range(1, 100, 1) var Resolution := 30

const center_offset := 0.5
@export var Terrain_Max_Height = 5
@export var create_collision = false
@export var remove_collision = false

@export var smooth = 0.5 as float

var min_height = 0
var max_height = 1


func _ready():
	terrain_gen()


func terrain_gen():
	var a_mesh:ArrayMesh
	var surftool = SurfaceTool.new()
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in Resolution+1:
		for x in Resolution+1:
			var percent = Vector2(x, z)/Resolution
			var PointOnMesh = Vector3((percent.x-center_offset), 0, (percent.y-center_offset))
			var vertex = PointOnMesh * Terrain_Size;
			vertex.y = noise.get_noise_2d(vertex.x * smooth, vertex.z * smooth) * Terrain_Max_Height
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
	update_shader()
	
	
func update_shader():
	var mat = get_active_material(0)
	mat.set_shader_parameter("min_height", min_height)
	mat.set_shader_parameter("max_height", max_height)
	
var last_res = 0
var last_size = 0
var last_height = 0
var last_smooth = 0



func draw_sphere(pos:Vector3):
	var ins = MeshInstance3D.new()
	add_child(ins)
	ins.position = pos
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	ins.mesh = sphere
		
func _process(_delta):
	if Resolution != last_res or Terrain_Size != last_size or \
		Terrain_Max_Height != last_height or smooth != last_smooth:
			terrain_gen()
			last_res = Resolution
			last_size = Terrain_Size
			last_height = Terrain_Max_Height
			last_smooth = smooth
			
	if remove_collision:
		clear_collision()
		remove_collision = false
	if create_collision:
		create_trimesh_collision()
		create_collision = false
	
func generate_collision():
	clear_collision()
	create_trimesh_collision()
	
func clear_collision():
	if get_child_count() > 0:
		for i in get_children():
			i.free()

