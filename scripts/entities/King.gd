extends CharacterBody3D

# King.gd - Controlador do Rei Teodoro e seu pônei guloso Biscoito
# Movimenta-se pelo mapa isométrico, atrai moedas e lidera a formação de tropas

@export var move_speed: float = 6.2
@export var rotation_speed: float = 12.0
@export var base_magnet_radius: float = 6.0
@export var formation_radius: float = 2.4

var move_direction: Vector3 = Vector3.ZERO
var input_vector: Vector2 = Vector2.ZERO
var trot_time: float = 0.0
var step_timer: float = 0.0
var idle_time: float = 0.0
var base_visual_scale: Vector3 = Vector3.ONE

const PUFF_SCENE: PackedScene = preload("res://scenes/entities/PuffEffect.tscn")

@onready var coin_stack: Node3D = $CoinStack
@onready var magnet_area: Area3D = $MagnetArea
@onready var magnet_shape: CollisionShape3D = $MagnetArea/CollisionShape3D
@onready var formation_aura: MeshInstance3D = $FormationAura
@onready var visuals: Node3D = $Visuals

var foot_hero: Node3D = null
var _vehicle_mode: bool = false
var _size_multiplier: float = 1.0

const HERO_LOOKS := {
	"teodoro": {"model": "knight", "height": 3.05, "tint": Color.WHITE},
	"marta": {"model": "barbarian", "height": 3.05, "tint": Color.WHITE},
	"fidelio": {"model": "mage", "height": 3.05, "tint": Color.WHITE},
	"rosa": {"model": "rogue_hooded", "height": 3.05, "tint": Color.WHITE},
	"clara": {"model": "mage", "height": 2.95, "tint": Color(1.15, 1.15, 1.05)},
	"bento": {"model": "barbarian", "height": 3.35, "tint": Color(1.08, 0.92, 0.72)},
	"barao": {"model": "rogue", "height": 3.05, "tint": Color(0.85, 0.90, 1.00)},
}

func _ready() -> void:
	GameState.king_node = self
	base_visual_scale = visuals.scale
	GameState.hero_ability_used.connect(_on_hero_ability_used)
	_apply_hero_passives()
	_apply_hero_visuals()
	_setup_magnet()

func refresh_hero_appearance() -> void:
	_apply_hero_visuals()

func apply_size_multiplier(factor: float) -> void:
	_size_multiplier = factor
	visuals.scale = base_visual_scale * factor

func _apply_hero_visuals() -> void:
	var hero_id = str(SaveManager.save_data.get("selected_hero", "teodoro"))
	var horse := visuals.get_node_or_null("Horse")
	var rider := visuals.get_node_or_null("KingRider")
	if foot_hero and is_instance_valid(foot_hero):
		foot_hero.queue_free()
		foot_hero = null
	_vehicle_mode = hero_id == "teodoro"
	if horse:
		horse.visible = false
	if rider:
		rider.visible = false
	_build_foot_hero(hero_id)

func _build_foot_hero(hero_id: String) -> void:
	var look: Dictionary = HERO_LOOKS.get(hero_id, HERO_LOOKS["teodoro"])
	var foot := Node3D.new()
	foot.name = "FootHero"
	visuals.add_child(foot)
	var height: float = look.get("height", 3.05)
	var model: Node3D = load("res://scripts/effects/ChibiModel.gd").spawn(foot, str(look["model"]), height, look.get("tint", Color.WHITE), false, true)
	if model == null:
		return
	if hero_id == "teodoro":
		_add_crown(foot, height)
	foot_hero = foot

func _add_crown(parent: Node3D, head_height: float) -> void:
	var crown := Node3D.new()
	crown.name = "ChibiCrown"
	crown.position = Vector3(0, head_height * 0.98, 0)
	parent.add_child(crown)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.13
	torus.outer_radius = 0.17
	ring.mesh = torus
	ring.material_override = Art.mat(Art.GOLD, 0.35, 0.45)
	crown.add_child(ring)
	for i in range(5):
		var ang := TAU * float(i) / 5.0
		Art.cone(crown, 0.05, 0.18, Vector3(cos(ang) * 0.14, 0.1, sin(ang) * 0.14), Art.GOLD, 6)
	Art.sphere(crown, 0.04, Vector3(0, 0.02, 0.17), Art.ROYAL_RED)

func _model_bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var xf := model.global_transform.affine_inverse() * mi.global_transform
		var a: AABB = xf * mi.get_aabb()
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	return box

func _build_hero_prop(parent: Node3D, kind: String, accent: Color) -> void:
	match kind:
		"hammer":
			Art.cyl(parent, 0.055, 0.065, 1.15, Vector3(0.52, 0.8, 0.12), Art.WOOD_DARK, 8)
			Art.box(parent, Vector3(0.44, 0.24, 0.24), Vector3(0.52, 1.4, 0.12), Art.STONE)
		"staff":
			Art.cyl(parent, 0.05, 0.05, 2.25, Vector3(0.55, 1.15, 0.1), Art.WOOD_DARK, 8)
			var orb := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.17
			sphere.height = 0.34
			orb.mesh = sphere
			orb.material_override = Art.mat(accent, 0.35, 1.6)
			orb.position = Vector3(0.55, 2.35, 0.1)
			parent.add_child(orb)
		"shield":
			Art.cyl(parent, 0.36, 0.36, 0.12, Vector3(-0.44, 1.2, 0.14), accent, 12, Vector3(PI * 0.5, 0.0, 0.0))
			Art.cyl(parent, 0.16, 0.16, 0.15, Vector3(-0.44, 1.2, 0.21), Art.GOLD, 12, Vector3(PI * 0.5, 0.0, 0.0))
		"club":
			Art.cyl(parent, 0.2, 0.11, 1.45, Vector3(0.58, 0.85, 0.1), Art.WOOD, 8)
		"sword":
			Art.box(parent, Vector3(0.06, 0.95, 0.14), Vector3(0.5, 1.0, 0.2), Art.WHITE)
			Art.box(parent, Vector3(0.28, 0.06, 0.18), Vector3(0.5, 0.53, 0.2), Art.GOLD)

func _apply_hero_passives() -> void:
	var hero_id = SaveManager.save_data.get("selected_hero", "teodoro")
	if hero_id == "teodoro":
		# Teodoro tem ímã 35% maior
		base_magnet_radius *= 1.35
	
	# Bônus do Estábulo da Vila
	var stable_lvl = SaveManager.save_data.get("village_buildings", {}).get("stable", 1)
	move_speed += (stable_lvl - 1) * 0.25

func _setup_magnet() -> void:
	if magnet_shape and magnet_shape.shape is SphereShape3D:
		magnet_shape.shape.radius = base_magnet_radius
	
	magnet_area.area_entered.connect(_on_magnet_area_entered)

func set_input_direction(dir: Vector2) -> void:
	input_vector = dir
	
	# Transforma o input da tela (2D) para o plano isométrico (rotação de 45 graus)
	# Na visualização isométrica a 45°, X e Z são rotacionados
	var iso_x = (dir.x + dir.y) * 0.7071
	var iso_z = (dir.y - dir.x) * 0.7071
	move_direction = Vector3(iso_x, 0, iso_z).normalized() * dir.length()

func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	# Suporte a teclado (WASD / Setas) caso esteja no PC ou controle físico
	var key_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if key_input.length_squared() > 0.01:
		set_input_direction(key_input)
	
	if move_direction.length_squared() > 0.01:
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
		
		# Animação procedural de trote galante do cavalo Biscoito
		trot_time += delta * 15.0
		visuals.position.y = abs(sin(trot_time)) * 0.12
		visuals.rotation.x = sin(trot_time) * 0.05
		
		# Partículas suaves de poeira nas patas do cavalo
		step_timer += delta
		if step_timer >= 0.24:
			step_timer = 0.0
			var spawn_pos = global_position - visuals.transform.basis.z * 0.35
			var puff := PUFF_SCENE.instantiate()
			get_parent().add_child(puff)
			puff.follow(self, spawn_pos - global_position)
		
		# Rotação suave do personagem na direção do movimento
		# Os visuais do cavalo foram modelados apontando para +Z.
		var target_angle = atan2(move_direction.x, move_direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * 8.0 * delta)
		# Respiração suave em repouso: o Rei "respira" sem animação extra.
		idle_time += delta * 2.2
		visuals.position.y = lerp(visuals.position.y, sin(idle_time) * 0.025, 10.0 * delta)
		visuals.rotation.x = lerp(visuals.rotation.x, 0.0, 10.0 * delta)
	
	move_and_slide()
	
	# Limita o movimento do Rei estritamente dentro da área do diorama
	global_position.x = clamp(global_position.x, -26.0, 26.0)
	global_position.z = clamp(global_position.z, -26.0, 26.0)

# Impacto visual claro ao usar a habilidade do herói (escala com overshoot, sem mudar a lógica).
func _on_hero_ability_used(_hero_id: String) -> void:
	if not visuals:
		return
	var tw := create_tween()
	tw.tween_property(visuals, "scale", base_visual_scale * 1.14, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visuals, "scale", base_visual_scale, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_magnet_area_entered(area: Area3D) -> void:
	if area.is_in_group("coins"):
		if area.has_method("attract_to"):
			area.attract_to(self)

func get_formation_position(index: int, total: int) -> Vector3:
	# Distribui tropas em anéis concêntricos ao redor do Rei
	if total <= 0:
		return global_position
		
	var ring = 1
	var ring_capacity = 6
	var remaining_idx = index
	var current_radius = formation_radius
	
	while remaining_idx >= ring_capacity:
		remaining_idx -= ring_capacity
		ring += 1
		ring_capacity = ring * 6
		current_radius += 1.2
	
	var angle_step = TAU / float(ring_capacity)
	var angle = remaining_idx * angle_step
	var offset = Vector3(cos(angle) * current_radius, 0, sin(angle) * current_radius)
	return global_position + offset
