extends MultiMeshInstance3D

const FLOWER_POSITIONS: Array[Vector3] = [
	Vector3(-12.0, 0.12, -9.0),
	Vector3(-12.0, 0.12, -4.0),
	Vector3(-12.0, 0.12, 2.0),
	Vector3(-12.0, 0.12, 8.0),
	Vector3(-8.0, 0.12, 11.0),
	Vector3(-3.0, 0.12, 11.0),
	Vector3(2.0, 0.12, 11.0),
	Vector3(7.0, 0.12, 11.0),
	Vector3(13.0, 0.12, 8.0),
	Vector3(14.0, 0.12, 3.0),
	Vector3(14.0, 0.12, -3.0),
	Vector3(12.0, 0.12, -9.0),
	Vector3(7.0, 0.12, -11.0),
	Vector3(2.0, 0.12, -11.0),
	Vector3(-3.0, 0.12, -11.0),
	Vector3(-8.0, 0.12, -11.0)
]

const FLOWER_COLORS: Array[Color] = [
	Color("#F3C54B"),
	Color("#E97872"),
	Color("#F4E7C3"),
	Color("#A57BC4")
]

func _ready() -> void:
	multimesh = _build_multimesh()
	material_override = _build_material()

func _build_multimesh() -> MultiMesh:
	var flower_mesh := _build_flower_mesh()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = flower_mesh
	instances.instance_count = FLOWER_POSITIONS.size()

	for index in range(FLOWER_POSITIONS.size()):
		var scale := 0.85 + float(index % 3) * 0.12
		var transform := Transform3D.IDENTITY
		transform.origin = FLOWER_POSITIONS[index]
		transform.basis = transform.basis.scaled(Vector3.ONE * scale)
		instances.set_instance_transform(index, transform)
		instances.set_instance_color(index, FLOWER_COLORS[index % FLOWER_COLORS.size()])

	return instances

func _build_flower_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array([Vector3.ZERO])
	var normals := PackedVector3Array([Vector3.UP])
	var indices := PackedInt32Array()
	const POINTS := 12

	for point_index in range(POINTS):
		var angle := -TAU * float(point_index) / POINTS
		var radius := 0.19 if point_index % 2 == 0 else 0.075
		vertices.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
		normals.append(Vector3.UP)

	for point_index in range(POINTS):
		var next_index := (point_index + 1) % POINTS
		indices.append_array(PackedInt32Array([0, point_index + 1, next_index + 1]))

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var flower := ArrayMesh.new()
	flower.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return flower

func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.85
	return material