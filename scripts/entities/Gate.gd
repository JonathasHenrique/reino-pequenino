extends Node3D

# Gate.gd - Portão de madeira do perímetro de paliçadas.
# Rei e arqueiras aliadas passam (a porta abre ao se aproximarem).
# Inimigos nunca passam: têm um bloqueio próprio na camada 2, sempre ativo.
# Vira alvo de inimigos (grupo "palisades") como as paliçadas comuns.

const HealthBar3D = preload("res://scripts/entities/HealthBar3D.gd")
const GATE_MODEL := "res://assets/models/castle/gate.glb"
const OPEN_ANGLE := -1.7
const CLOSE_DELAY := 0.9

const WOOD_COLOR := Color(0.55, 0.36, 0.2)
const WOOD_DARK := Color(0.36, 0.22, 0.12)

@export var max_hp: int = 260
var current_hp: int = 260
var alive: bool = true

var health_bar: MeshInstance3D = null
var door_pivot: Node3D
var king_block: CollisionShape3D
var allies_inside: int = 0
var close_timer: float = 0.0
var is_open: bool = false
var door_tween: Tween

func _ready() -> void:
	current_hp = max_hp
	add_to_group("palisades")
	_build_side_walls()
	_build_door()
	health_bar = HealthBar3D.create(self, 2.4, 1.8, Color(0.35, 0.85, 0.30), false)
	_update_ui()

func _process(delta: float) -> void:
	if not alive:
		return
	if allies_inside <= 0 and is_open:
		close_timer -= delta
		if close_timer <= 0.0:
			_set_open(false)

func _build_side_walls() -> void:
	# Paliçada lateral de cada lado da porta. Bloqueia Rei, aliadas e inimigos.
	for side in [-1.0, 1.0]:
		var body := StaticBody3D.new()
		body.name = "SideWall"
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector3(side * 2.55, 0, 0)
		add_child(body)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(3.5, 2.0, 1.0)
		shape.shape = box
		shape.position = Vector3(0, 1.0, 0)
		body.add_child(shape)
		for i in range(5):
			var log := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.14
			cyl.bottom_radius = 0.16
			cyl.height = 2.0
			log.mesh = cyl
			log.material_override = _wood(WOOD_COLOR)
			log.position = Vector3(-1.5 + i * 0.75, 1.0, 0.0)
			body.add_child(log)
		for y in [0.45, 1.6]:
			var beam := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(3.5, 0.18, 0.25)
			beam.mesh = bm
			beam.material_override = _wood(WOOD_DARK)
			beam.position = Vector3(0, y, 0)
			body.add_child(beam)

func _build_door() -> void:
	# Bloqueio para inimigos (camada 2): fica sempre ativo, mesmo com a porta aberta.
	var enemy_block := StaticBody3D.new()
	enemy_block.name = "EnemyBlock"
	enemy_block.collision_layer = 2
	enemy_block.collision_mask = 0
	add_child(enemy_block)
	var eshape := CollisionShape3D.new()
	var ebox := BoxShape3D.new()
	ebox.size = Vector3(1.6, 2.0, 0.35)
	eshape.shape = ebox
	eshape.position = Vector3(0, 1.0, 0)
	enemy_block.add_child(eshape)

	# Bloqueio para Rei e aliadas (camada 1): só existe com a porta fechada.
	var king_body := StaticBody3D.new()
	king_body.name = "KingBlock"
	king_body.collision_layer = 1
	king_body.collision_mask = 0
	add_child(king_body)
	king_block = CollisionShape3D.new()
	var kbox := BoxShape3D.new()
	kbox.size = Vector3(1.6, 2.0, 0.35)
	king_block.shape = kbox
	king_block.position = Vector3(0, 1.0, 0)
	king_body.add_child(king_block)

	# Folha da porta, presa numa dobradiça à esquerda da abertura.
	door_pivot = Node3D.new()
	door_pivot.name = "DoorPivot"
	door_pivot.position = Vector3(-0.8, 0, 0)
	add_child(door_pivot)
	var model := load(GATE_MODEL) as PackedScene
	if model:
		var leaf := model.instantiate() as Node3D
		leaf.scale = Vector3.ONE * 2.4
		leaf.rotation.y = PI / 2.0
		leaf.position = Vector3(0.8, 0, 0)
		door_pivot.add_child(leaf)

	# Área de detecção: aliadas por perto abrem a porta.
	var area := Area3D.new()
	area.name = "Trigger"
	area.collision_layer = 0
	area.collision_mask = 1
	add_child(area)
	var ashape := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(3.0, 2.0, 2.6)
	ashape.shape = abox
	ashape.position = Vector3(0, 1.0, 0)
	area.add_child(ashape)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _is_passer(body: Node3D) -> bool:
	return body == GameState.king_node or body.is_in_group("troops")

func _on_body_entered(body: Node3D) -> void:
	if _is_passer(body):
		allies_inside += 1
		close_timer = CLOSE_DELAY
		if alive:
			_set_open(true)

func _on_body_exited(body: Node3D) -> void:
	if _is_passer(body):
		allies_inside = maxi(0, allies_inside - 1)
		close_timer = CLOSE_DELAY

func _set_open(open: bool) -> void:
	if is_open == open:
		return
	is_open = open
	king_block.set_deferred("disabled", open)
	if door_tween and door_tween.is_running():
		door_tween.kill()
	door_tween = create_tween()
	door_tween.tween_property(door_pivot, "rotation:y", OPEN_ANGLE if open else 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	if open:
		AudioManager.play_sfx("hero_skill")

func _wood(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m

func take_damage(amount: int) -> void:
	if not alive:
		return
	current_hp = maxi(0, current_hp - amount)
	_update_ui()
	AudioManager.play_sfx("hit")
	if current_hp <= 0:
		_break_gate()

func _update_ui() -> void:
	if health_bar:
		health_bar.set_ratio(float(current_hp) / float(max_hp))

func repair_fully() -> void:
	current_hp = max_hp
	_update_ui()
	Art.pop_in(self)

func _break_gate() -> void:
	alive = false
	AudioManager.play_sfx("puff")
	Art.dust_puff(get_parent(), global_position + Vector3(0, 1.0, 0), 10)
	queue_free()
