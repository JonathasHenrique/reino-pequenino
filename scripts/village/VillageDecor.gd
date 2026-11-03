extends Node3D

# VillageDecor.gd - Cenário decorativo da Vila do Rei.
# Monta um castelo de fundo (Kenney Castle Kit, CC0) fora dos muros, árvores ao redor
# e postes de luz nos cantos da praça. Nada aqui é caminho ou área de compra:
# os postes têm colisão só no fuste, longe das estradas e do centro.

const CASTLE_DIR := "res://assets/models/castle/"
const CASTLE_SCALE := 1.8
const CASTLE_POS := Vector3(-19.0, 0.0, -21.0)
const CASTLE_YAW := PI / 4.0 # frente do castelo voltada para a Vila

@export var build_on_ready: bool = true

func _ready() -> void:
	if not build_on_ready:
		return
	_build_castle()
	_build_trees()
	_build_lamp_posts()

func _piece(piece_name: String) -> Node3D:
	var packed := load(CASTLE_DIR + piece_name + ".glb") as PackedScene
	if packed == null:
		push_warning("Peça de castelo não encontrada: " + piece_name)
		return null
	return packed.instantiate() as Node3D

func _place(parent: Node3D, piece_name: String, pos: Vector3, yaw: float = 0.0) -> void:
	var node := _piece(piece_name)
	if node == null:
		return
	node.position = pos
	node.rotation.y = yaw
	parent.add_child(node)

func _build_castle() -> void:
	var castle := Node3D.new()
	castle.name = "CastleBackdrop"
	castle.position = CASTLE_POS
	castle.rotation.y = CASTLE_YAW
	castle.scale = Vector3.ONE * CASTLE_SCALE
	add_child(castle)

	# Torres de canto: base + dois andares + telhado com bandeira
	for sx in [-2.0, 2.0]:
		for sz in [-2.0, 2.0]:
			var p := Vector3(sx, 0.0, sz)
			_place(castle, "tower-square-base", p)
			_place(castle, "tower-square-mid-windows", p + Vector3(0, 1.01, 0))
			_place(castle, "tower-square-top-roof-high", p + Vector3(0, 2.02, 0))
			_place(castle, "flag-banner-long", p + Vector3(0, 3.37, 0))

	# Torre central (keep), mais alta que as de canto
	_place(castle, "tower-square-base", Vector3.ZERO)
	_place(castle, "tower-square-mid-windows", Vector3(0, 1.01, 0))
	_place(castle, "tower-square-mid-windows", Vector3(0, 2.02, 0))
	_place(castle, "tower-square-top-roof-high", Vector3(0, 3.03, 0))
	_place(castle, "flag-banner-long", Vector3(0, 4.38, 0))

	# Muralhas entre as torres (lado frontal com portão em z = +2)
	for x in [-1.0, 0.0, 1.0]:
		_place(castle, "wall", Vector3(x, 0.0, -2.0))
		if x == 0.0:
			_place(castle, "wall-doorway", Vector3(x, 0.0, 2.0))
		else:
			_place(castle, "wall", Vector3(x, 0.0, 2.0))
	for z in [-1.0, 0.0, 1.0]:
		_place(castle, "wall", Vector3(-2.0, 0.0, z), PI / 2.0)
		_place(castle, "wall", Vector3(2.0, 0.0, z), PI / 2.0)

	# Pedras e árvores na base do castelo
	_place(castle, "rocks-large", Vector3(-3.2, 0.0, 2.6))
	_place(castle, "tree-large", Vector3(3.4, 0.0, 3.2))
	_place(castle, "tree-small", Vector3(-3.6, 0.0, -1.2))

func _build_trees() -> void:
	var scenery := Node3D.new()
	scenery.name = "OuterTrees"
	add_child(scenery)
	var spots := [
		[Vector3(-31.0, 0.0, 8.0), "tree-large"],
		[Vector3(-31.0, 0.0, 19.0), "tree-small"],
		[Vector3(31.0, 0.0, -10.0), "tree-large"],
		[Vector3(31.0, 0.0, 6.0), "tree-small"],
		[Vector3(30.0, 0.0, 22.0), "tree-large"],
		[Vector3(-12.0, 0.0, -31.0), "tree-large"],
		[Vector3(8.0, 0.0, -31.0), "tree-small"],
		[Vector3(18.0, 0.0, 31.0), "tree-large"],
	]
	for spot in spots:
		_place(scenery, str(spot[1]), spot[0], float(spot[0].x) * 0.07)

func _build_lamp_posts() -> void:
	var lamps := Node3D.new()
	lamps.name = "PlazaLamps"
	add_child(lamps)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.22, 0.2, 0.22)
	iron.roughness = 0.6
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.85, 0.45)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.8, 0.35)
	glow.emission_energy_multiplier = 1.4
	for sx in [-8.0, 8.0]:
		for sz in [-8.0, 8.0]:
			var post := StaticBody3D.new()
			post.position = Vector3(sx, 0.0, sz)
			lamps.add_child(post)

			var pole := MeshInstance3D.new()
			var pole_mesh := CylinderMesh.new()
			pole_mesh.top_radius = 0.05
			pole_mesh.bottom_radius = 0.09
			pole_mesh.height = 1.9
			pole.mesh = pole_mesh
			pole.material_override = iron
			pole.position = Vector3(0, 0.95, 0)
			post.add_child(pole)

			var lantern := MeshInstance3D.new()
			var orb := SphereMesh.new()
			orb.radius = 0.2
			orb.height = 0.4
			lantern.mesh = orb
			lantern.material_override = glow
			lantern.position = Vector3(0, 2.0, 0)
			post.add_child(lantern)

			var shape := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = 0.12
			cyl.height = 1.9
			shape.shape = cyl
			shape.position = Vector3(0, 0.95, 0)
			post.add_child(shape)
