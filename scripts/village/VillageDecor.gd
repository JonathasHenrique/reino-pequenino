extends Node3D

# VillageDecor.gd - Cenário decorativo da Vila do Rei.
# Monta um castelo de fundo (Kenney Castle Kit, CC0) fora dos muros, árvores ao redor
# e postes de luz nos cantos da praça. Nada aqui é caminho ou área de compra:
# os postes têm colisão só no fuste, longe das estradas e do centro.

const CASTLE_DIR := "res://assets/models/castle/"
const CASTLE_SCALE := 2.0
const CASTLE_POS := Vector3(0.0, 0.0, -18.0)
const CASTLE_YAW := 0.0
const KING_SPAWN := Vector3(0.0, 0.0, -8.5)
const KING_GATE := Vector3(0.0, 0.0, -11.2)

@export var build_on_ready: bool = true

func _ready() -> void:
	if not build_on_ready:
		return
	_build_castle()
	_build_trees()
	_build_lamp_posts()
	_build_plaza_props()
	_build_city_props()
	_build_villagers()
	# Os modelos importados recebem material toon de forma diferida; espera e funde.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_merge_static()

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

	# Torres de canto da muralha
	for sx in [-3.0, 3.0]:
		for sz in [-3.0, 3.0]:
			var p := Vector3(sx, 0.0, sz)
			_place(castle, "tower-square-base", p)
			_place(castle, "tower-square-mid-windows", p + Vector3(0, 1.01, 0))
			_place(castle, "tower-square-top-roof-high", p + Vector3(0, 2.02, 0))
			_place(castle, "flag-pennant", p + Vector3(0, 3.37, 0))

	# Torre central (keep), mais alta e recuada
	_place(castle, "tower-square-base", Vector3(0, 0.0, -1.0))
	_place(castle, "tower-square-mid-windows", Vector3(0, 1.01, -1.0))
	_place(castle, "tower-square-mid-windows", Vector3(0, 2.02, -1.0))
	_place(castle, "tower-square-top-roof-high", Vector3(0, 3.03, -1.0))
	_place(castle, "flag-pennant", Vector3(0, 4.38, -1.0))

	# Muralha: frente com portão central, fundo e laterais
	for x in [-2.0, -1.0, 1.0, 2.0]:
		_place(castle, "wall", Vector3(x, 0.0, 3.0))
		_place(castle, "wall", Vector3(x, 0.0, -3.0))
	_place(castle, "wall-doorway", Vector3(0, 0.0, 3.0))
	for z in [-2.0, -1.0, 0.0, 1.0, 2.0]:
		_place(castle, "wall", Vector3(-3.0, 0.0, z), PI / 2.0)
		_place(castle, "wall", Vector3(3.0, 0.0, z), PI / 2.0)

	# Piso do pátio interno
	var yard := MeshInstance3D.new()
	var ym := BoxMesh.new()
	ym.size = Vector3(5.6, 0.08, 5.6)
	yard.mesh = ym
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.70, 0.66, 0.58)
	stone.roughness = 0.95
	yard.material_override = stone
	yard.position = Vector3(0, 0.12, 0)
	castle.add_child(yard)

	_build_castle_collision(castle)

	# Pedras e árvores na base do castelo
	_place(castle, "rocks-large", Vector3(-4.2, 0.0, 3.6))
	_place(castle, "tree-large", Vector3(4.4, 0.0, 4.2))
	_place(castle, "tree-small", Vector3(-4.6, 0.0, -1.2))

func _build_castle_collision(castle: Node3D) -> void:
	var walls := StaticBody3D.new()
	walls.name = "CastleWalls"
	castle.add_child(walls)
	var boxes := [
		[Vector3(-1.6, 1.5, 3.0), Vector3(2.8, 3.0, 0.6)],
		[Vector3(1.6, 1.5, 3.0), Vector3(2.8, 3.0, 0.6)],
		[Vector3(0.0, 1.5, -3.0), Vector3(6.6, 3.0, 0.6)],
		[Vector3(-3.0, 1.5, 0.0), Vector3(0.6, 3.0, 6.6)],
		[Vector3(3.0, 1.5, 0.0), Vector3(0.6, 3.0, 6.6)],
	]
	for b in boxes:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = b[1]
		cs.shape = shape
		cs.position = b[0]
		walls.add_child(cs)
	var keep := StaticBody3D.new()
	keep.name = "CastleKeep"
	castle.add_child(keep)
	var kcs := CollisionShape3D.new()
	var kbox := BoxShape3D.new()
	kbox.size = Vector3(2.6, 4.0, 2.6)
	kcs.shape = kbox
	kcs.position = Vector3(0, 2.0, -1.0)
	keep.add_child(kcs)

func _build_castle_ground() -> void:
	var ground := Node3D.new()
	ground.name = "CastleGround"
	add_child(ground)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.66, 0.62, 0.55)
	stone.roughness = 0.95

	var yard := MeshInstance3D.new()
	var ym := BoxMesh.new()
	ym.size = Vector3(9.0, 0.08, 5.0)
	yard.mesh = ym
	yard.material_override = stone
	yard.position = CASTLE_POS + Vector3(0.0, 0.06, 8.0)
	yard.rotation.y = CASTLE_YAW
	ground.add_child(yard)

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

func _build_plaza_props() -> void:
	# Canteiros e pedras nas quinas da praça, longe das estradas e do centro.
	var props := Node3D.new()
	props.name = "PlazaProps"
	add_child(props)
	var flower = load("res://scenes/props/FlowerPatch.tscn") as PackedScene
	var rock = load("res://scenes/props/Rock.tscn") as PackedScene
	var fence = load("res://scenes/props/WoodenFence.tscn") as PackedScene
	var spots := [
		[Vector3(-7.0, 0.0, -7.0), flower],
		[Vector3(7.0, 0.0, -7.0), flower],
		[Vector3(-7.0, 0.0, 7.0), flower],
		[Vector3(7.0, 0.0, 7.0), flower],
		[Vector3(-8.6, 0.0, -8.6), rock],
		[Vector3(8.6, 0.0, 8.6), rock],
		[Vector3(-15.5, 0.0, -9.5), fence],
		[Vector3(15.5, 0.0, 9.5), fence],
	]
	for spot in spots:
		var scene: PackedScene = spot[1]
		if scene == null:
			continue
		var inst := scene.instantiate() as Node3D
		inst.position = spot[0]
		props.add_child(inst)

func _build_city_props() -> void:
	var props := Node3D.new()
	props.name = "CityProps"
	add_child(props)
	var wagon = load("res://assets/models/village_kit/Prop_Wagon.gltf") as PackedScene
	var crate = load("res://assets/models/village_kit/Prop_Crate.gltf") as PackedScene
	var fence = load("res://assets/models/village_kit/Prop_WoodenFence_Single.gltf") as PackedScene
	if wagon:
		for spot in [Vector3(6.5, 0, 12.0), Vector3(-8.0, 0, -11.0)]:
			var w := wagon.instantiate() as Node3D
			w.position = spot
			w.rotation.y = spot.x * 0.3
			props.add_child(w)
	if crate:
		for spot in [Vector3(4.0, 0, -11.5), Vector3(4.8, 0, -12.3), Vector3(-5.0, 0, 11.0)]:
			var c := crate.instantiate() as Node3D
			c.position = spot
			c.rotation.y = spot.x * 0.5
			props.add_child(c)
	if fence:
		for spot in [Vector3(-7.0, 0, -8.0), Vector3(-9.0, 0, -8.0), Vector3(7.0, 0, 8.0)]:
			var f := fence.instantiate() as Node3D
			f.position = spot
			props.add_child(f)

func _build_villagers() -> void:
	var villagers := Node3D.new()
	villagers.name = "Villagers"
	add_child(villagers)
	var models := ["mage", "rogue", "barbarian", "knight"]
	var paths := [
		[Vector3(-5, 0, -4), Vector3(-7, 0, 4), Vector3(-2, 0, 7)],
		[Vector3(5, 0, -4), Vector3(8, 0, 3), Vector3(4, 0, 7)],
		[Vector3(-6, 0, 9), Vector3(2, 0, 10), Vector3(6, 0, 8)],
		[Vector3(9, 0, -8), Vector3(3, 0, -10), Vector3(-3, 0, -8)],
	]
	for i in range(models.size()):
		var bot := Node3D.new()
		bot.set_script(load("res://scripts/village/VillagerBot.gd"))
		villagers.add_child(bot)
		bot.position = paths[i][0]
		var model: Node3D = load("res://scripts/effects/ChibiModel.gd").spawn(bot, models[i], 2.6)
		bot.set("waypoints", paths[i])
		bot.set("model", model)

func get_king_spawn() -> Vector3:
	return KING_SPAWN

func get_king_gate() -> Vector3:
	return KING_GATE

func get_castle_center() -> Vector3:
	return CASTLE_POS + Vector3(0, 4.2, 0)

func _merge_static() -> void:
	var merger = load("res://scripts/core/StaticMeshMerger.gd")
	for node_name in ["CastleBackdrop", "CastleGround", "OuterTrees", "PlazaLamps", "PlazaProps", "CityProps"]:
		var n := get_node_or_null(node_name) as Node3D
		if n:
			merger.merge_subtree(n, ["Label3D"], false, true)

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
