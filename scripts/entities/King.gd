extends CharacterBody3D

# King.gd - Controlador do Rei Teodoro e seu pônei guloso Biscoito
# Movimenta-se pelo mapa isométrico, atrai moedas e lidera a formação de tropas

@export var move_speed: float = 6.2
@export var rotation_speed: float = 12.0
@export var base_magnet_radius: float = 4.5
@export var formation_radius: float = 2.4

var move_direction: Vector3 = Vector3.ZERO
var input_vector: Vector2 = Vector2.ZERO
var trot_time: float = 0.0
var step_timer: float = 0.0

const PUFF_SCENE: PackedScene = preload("res://scenes/entities/PuffEffect.tscn")

@onready var coin_stack: Node3D = $CoinStack
@onready var magnet_area: Area3D = $MagnetArea
@onready var magnet_shape: CollisionShape3D = $MagnetArea/CollisionShape3D
@onready var formation_aura: MeshInstance3D = $FormationAura
@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	GameState.king_node = self
	_apply_hero_passives()
	_setup_magnet()

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
		visuals.position.y = lerp(visuals.position.y, 0.0, 10.0 * delta)
		visuals.rotation.x = lerp(visuals.rotation.x, 0.0, 10.0 * delta)
	
	move_and_slide()
	
	# Limita o movimento do Rei estritamente dentro da área do diorama
	global_position.x = clamp(global_position.x, -26.0, 26.0)
	global_position.z = clamp(global_position.z, -26.0, 26.0)

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
