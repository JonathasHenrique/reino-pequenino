extends RefCounted

# ModularHouse.gd - Monta casas medievais com o Quaternius Medieval Village MegaKit (CC0).
# Cada parede tem 2 m de largura e 3,12 m de altura; telhados cobrem casas de 4x4, 4x6 e 6x6.

const KIT := "res://assets/models/village_kit/"
const WALL_HEIGHT := 3.12
const WALL_STEP := 2.0

static var _cache: Dictionary = {}

static func _piece(piece_name: String) -> PackedScene:
	if _cache.has(piece_name):
		return _cache[piece_name]
	var packed := load(KIT + piece_name + ".gltf") as PackedScene
	_cache[piece_name] = packed
	return packed

static func _add(parent: Node3D, piece_name: String, pos: Vector3, yaw: float = 0.0) -> Node3D:
	var packed := _piece(piece_name)
	if packed == null:
		return null
	var node := packed.instantiate() as Node3D
	node.position = pos
	node.rotation.y = yaw
	parent.add_child(node)
	return node

static func build(container: Node3D, footprint: Vector2i, style: String = "plaster", level: int = 1, door_side: String = "south", roof_tint: Color = Color.WHITE) -> void:
	var wax := float(footprint.x)
	var waz := float(footprint.y)
	var half_x := wax * 0.5
	var half_z := waz * 0.5
	var straight := "Wall_Plaster_Straight" if style == "plaster" else "Wall_UnevenBrick_Straight"
	var door_piece := "Wall_Plaster_Door_Round" if style == "plaster" else "Wall_UnevenBrick_Door_Round"
	var window_piece := "Wall_Plaster_Window_Wide_Round" if style == "plaster" else "Wall_UnevenBrick_Window_Wide_Round"

	var panels_x := maxi(1, int(wax / WALL_STEP))
	var panels_z := maxi(1, int(waz / WALL_STEP))

	var windows: Array = []
	for i in range(panels_x):
		var x := -half_x + WALL_STEP * (i + 0.5)
		var north_piece := window_piece if (level >= 2 and i % 2 == 0) else straight
		_add(container, north_piece, Vector3(x, 0, -half_z), PI)
		if north_piece == window_piece:
			windows.append(Vector3(x, 0, -half_z))
		var south_piece := straight
		if door_side == "south" and i == panels_x / 2:
			south_piece = door_piece
		elif level >= 2 and i == 0:
			south_piece = window_piece
			windows.append(Vector3(x, 0, half_z))
		_add(container, south_piece, Vector3(x, 0, half_z), 0.0)
		if south_piece == door_piece:
			_add(container, "Door_1_Round", Vector3(x, 0, half_z + 0.16), 0.0)

	for i in range(panels_z):
		var z := -half_z + WALL_STEP * (i + 0.5)
		var east_piece := window_piece if (level >= 3 and i == panels_z / 2) else straight
		_add(container, straight, Vector3(-half_x, 0, z), -PI * 0.5)
		_add(container, east_piece, Vector3(half_x, 0, z), PI * 0.5)
		if east_piece == window_piece:
			windows.append(Vector3(half_x, 0, z))

	for w in windows:
		var wpos: Vector3 = w
		var yaw := 0.0
		if is_equal_approx(wpos.z, -half_z):
			yaw = PI
		elif is_equal_approx(wpos.x, half_x):
			yaw = PI * 0.5
		_add(container, "WindowShutters_Wide_Round_Closed", wpos + Vector3(0, 0, 0.05), yaw)

	for sx in [-half_x, half_x]:
		for sz in [-half_z, half_z]:
			_add(container, "Corner_Exterior_Brick", Vector3(sx, 0, sz))

	var roof := "Roof_RoundTiles_4x4"
	if int(wax) == 4 and int(waz) == 6:
		roof = "Roof_RoundTiles_4x6"
	elif int(wax) >= 6 and int(waz) >= 6:
		roof = "Roof_RoundTiles_6x6"
	var roof_node := _add(container, roof, Vector3(0, WALL_HEIGHT, 0))
	if roof_node and roof_tint != Color.WHITE:
		for m in roof_node.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			var mat := mi.get_active_material(0)
			if mat is BaseMaterial3D:
				var tinted := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				tinted.albedo_color = roof_tint
				mi.material_override = tinted

	var gable := "Roof_Front_Brick4" if int(wax) <= 4 else "Roof_Front_Brick6"
	_add(container, gable, Vector3(0, WALL_HEIGHT, half_z), 0.0)
	_add(container, gable, Vector3(0, WALL_HEIGHT, -half_z), PI)

	if level >= 2:
		_add(container, "Prop_Chimney", Vector3(half_x - 1.1, WALL_HEIGHT + 1.35, -half_z + 1.2))
	if level >= 3:
		_add(container, "Prop_Vine1", Vector3(-half_x + 0.05, WALL_HEIGHT * 0.5, half_z - 0.6), -PI * 0.5)

static func height_for(footprint: Vector2i) -> float:
	var base := 7.4
	if int(footprint.x) >= 6 or int(footprint.y) >= 6:
		base = 9.4
	return base
