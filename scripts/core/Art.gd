extends Node

# Art.gd - Paleta de cores e "fábrica" de peças 3D estilizadas do Reino Pequenino.
# Tudo é gerado por código (sem assets externos), com materiais reaproveitados
# em cache para manter poucos draw calls e 60 fps em celulares médios.

# ---------- PALETA (tons suaves de desenho animado, sem neon) ----------
const GRASS := Color(0.47, 0.71, 0.30)
const GRASS_DARK := Color(0.36, 0.60, 0.24)
const DIRT := Color(0.80, 0.66, 0.46)
const DIRT_DARK := Color(0.66, 0.52, 0.34)
const WOOD := Color(0.55, 0.36, 0.20)
const WOOD_DARK := Color(0.40, 0.25, 0.14)
const WOOD_LIGHT := Color(0.72, 0.52, 0.32)
const STONE := Color(0.62, 0.62, 0.60)
const STONE_DARK := Color(0.45, 0.46, 0.46)
const CLIFF := Color(0.52, 0.50, 0.46)
const ROYAL_BLUE := Color(0.18, 0.42, 0.85)
const ROYAL_RED := Color(0.82, 0.24, 0.20)
const GOLD := Color(1.0, 0.80, 0.18)
const WHITE := Color(0.97, 0.96, 0.92)
const LEAF := Color(0.33, 0.62, 0.25)
const LEAF_DARK := Color(0.22, 0.48, 0.20)
const MIST := Color(0.50, 0.55, 0.65)

static var _mat_cache: Dictionary = {}

# Material fosco e com leve brilho (visual "brinquedo de plástico/madeira")
static func mat(color: Color, roughness: float = 0.8, emission: float = 0.0) -> StandardMaterial3D:
	var key = "%s|%.2f|%.2f" % [color.to_html(), roughness, emission]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if color.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_mat_cache[key] = m
	return m

# Material "fantasma" (planta de construção azul translúcida)
static func ghost_mat() -> StandardMaterial3D:
	if _mat_cache.has("__ghost"):
		return _mat_cache["__ghost"]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.85, 1.0, 0.32)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	_mat_cache["__ghost"] = m
	return m

static func _add(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO, roughness: float = 0.8) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat(color, roughness)
	parent.add_child(mi)
	return mi

static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m = BoxMesh.new()
	m.size = size
	return _add(parent, m, pos, color, rot)

static func cyl(parent: Node3D, radius_top: float, radius_bottom: float, height: float, pos: Vector3, color: Color, sides: int = 10, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m = CylinderMesh.new()
	m.top_radius = radius_top
	m.bottom_radius = radius_bottom
	m.height = height
	m.radial_segments = sides
	m.rings = 1
	return _add(parent, m, pos, color, rot)

static func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, squash: float = 1.0) -> MeshInstance3D:
	var m = SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0 * squash
	m.radial_segments = 12
	m.rings = 6
	return _add(parent, m, pos, color)

static func cone(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, sides: int = 8) -> MeshInstance3D:
	return cyl(parent, 0.0, radius, height, pos, color, sides)

# Telhado de duas águas (prisma)
static func roof(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_y: float = 0.0) -> MeshInstance3D:
	var m = PrismMesh.new()
	m.size = size
	return _add(parent, m, pos, color, Vector3(0, rot_y, 0))

# Etiqueta 3D grande, com contorno grosso, sempre virada para a câmera
static func label(parent: Node3D, text: String, pos: Vector3, font_size: int = 64, color: Color = Color.WHITE) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = font_size
	l.outline_size = int(font_size * 0.28)
	l.outline_modulate = Color(0.12, 0.08, 0.05, 1)
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	# Tamanho fixo na TELA: legível no celular independente da distância da câmera
	# (64 px de fonte ~ 45 px de altura numa tela 720p)
	l.fixed_size = true
	l.pixel_size = 0.0007
	l.render_priority = 5
	l.outline_render_priority = 4
	parent.add_child(l)
	return l

# Árvore redonda estilizada (copa em 3 esferas)
static func tree(parent: Node3D, pos: Vector3, scale_f: float = 1.0) -> Node3D:
	var t = Node3D.new()
	t.position = pos
	t.scale = Vector3.ONE * scale_f
	t.rotation.y = randf() * TAU
	parent.add_child(t)
	cyl(t, 0.16, 0.24, 1.2, Vector3(0, 0.6, 0), WOOD_DARK, 6)
	sphere(t, 0.95, Vector3(0, 1.75, 0), LEAF)
	sphere(t, 0.65, Vector3(0.55, 1.45, 0.2), LEAF_DARK)
	sphere(t, 0.6, Vector3(-0.45, 1.55, -0.3), LEAF.lightened(0.1))
	return t

# Pinheiro em camadas
static func pine(parent: Node3D, pos: Vector3, scale_f: float = 1.0) -> Node3D:
	var t = Node3D.new()
	t.position = pos
	t.scale = Vector3.ONE * scale_f
	parent.add_child(t)
	cyl(t, 0.12, 0.18, 0.7, Vector3(0, 0.35, 0), WOOD_DARK, 6)
	cone(t, 0.95, 1.3, Vector3(0, 1.2, 0), LEAF_DARK)
	cone(t, 0.75, 1.1, Vector3(0, 1.8, 0), LEAF_DARK.lightened(0.08))
	cone(t, 0.5, 0.9, Vector3(0, 2.35, 0), LEAF)
	return t

static func rock(parent: Node3D, pos: Vector3, scale_f: float = 1.0) -> Node3D:
	var r = Node3D.new()
	r.position = pos
	r.scale = Vector3(scale_f, scale_f * 0.75, scale_f)
	r.rotation.y = randf() * TAU
	parent.add_child(r)
	sphere(r, 0.5, Vector3(0, 0.25, 0), STONE, 0.8)
	sphere(r, 0.32, Vector3(0.4, 0.15, 0.1), STONE_DARK, 0.8)
	return r

static func bush(parent: Node3D, pos: Vector3, scale_f: float = 1.0) -> Node3D:
	var b = Node3D.new()
	b.position = pos
	b.scale = Vector3.ONE * scale_f
	parent.add_child(b)
	sphere(b, 0.45, Vector3(0, 0.3, 0), LEAF_DARK, 0.8)
	sphere(b, 0.35, Vector3(0.35, 0.25, 0.1), LEAF, 0.8)
	return b

static func flowers(parent: Node3D, pos: Vector3) -> void:
	var cols = [Color(1, 0.85, 0.2), Color(1, 0.55, 0.65), Color(0.95, 0.95, 1.0), Color(0.7, 0.55, 1.0)]
	for i in range(5):
		var off = Vector3(randf_range(-0.6, 0.6), 0.12, randf_range(-0.6, 0.6))
		sphere(parent, 0.09, pos + off, cols[randi() % cols.size()])

# Mostra um "pulo" de construção (escala elástica) — feedback suculento
static func pop_in(node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	var final_scale = node.scale
	node.scale = final_scale * 0.2
	var tw = node.create_tween()
	tw.tween_property(node, "scale", final_scale * 1.12, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", final_scale, 0.12)

# Nuvem de poeira de construção
static func dust_puff(parent: Node, pos: Vector3, amount: int = 14) -> void:
	if Settings.reduced_effects:
		return
	var p = CPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.7
	p.explosiveness = 0.95
	p.direction = Vector3(0, 1, 0)
	p.spread = 80.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.0
	p.gravity = Vector3(0, -3, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var m = SphereMesh.new()
	m.radius = 0.18
	m.height = 0.36
	m.radial_segments = 6
	m.rings = 3
	m.material = mat(Color(0.93, 0.88, 0.78))
	p.mesh = m
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)
