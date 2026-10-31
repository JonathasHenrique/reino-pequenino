extends CharacterBody3D

# Enemy.gd - Classe base para os invasores da Bruma Cinzenta
# Avança em direção ao Rei e defesas; solta 'puf' e moedas ao ser derrotado

signal died(enemy: Node3D)

@export var enemy_id: String = "misty_runner"
@export var base_hp: int = 24
@export var move_speed: float = 3.2
@export var damage: int = 6
@export var attack_range: float = 1.3
@export var attack_rate: float = 1.0
@export var coin_drop_count: int = 2
@export var is_flying: bool = false

var current_hp: int = 24
var attack_timer: float = 0.0
var alive: bool = true

@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	# Escalonamento de +8% de HP por fase a partir da fase 1
	var stage_scale = pow(1.08, float(maxi(0, GameState.current_stage - 1)))
	var diff_scale = 1.0
	match Settings.difficulty:
		Settings.Difficulty.TRANQUILO:
			diff_scale = 0.75
		Settings.Difficulty.VETERANO:
			diff_scale = 1.20
	current_hp = int(base_hp * stage_scale * diff_scale)
	
	add_to_group("enemies")
	GameState.register_enemy(self)

func apply_look(scale_mult: float, tint: Color) -> void:
	if not visuals:
		visuals = $Visuals
	if visuals:
		visuals.scale = Vector3(scale_mult, scale_mult, scale_mult)
		var body_mesh = visuals.get_node_or_null("Body")
		if body_mesh and body_mesh is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = tint
			mat.roughness = 0.7
			body_mesh.material_override = mat

func _exit_tree() -> void:
	GameState.unregister_enemy(self)

func is_alive() -> bool:
	return alive

func _physics_process(delta: float) -> void:
	if not alive or GameState.is_game_over:
		velocity = Vector3.ZERO
		return
	
	attack_timer = maxf(0.0, attack_timer - delta)
	
	# Busca alvo: Paliçadas no caminho ou o Rei
	var target = _find_target()
	if target and is_instance_valid(target):
		var to_target = target.global_position - global_position
		if not is_flying:
			to_target.y = 0
			
		var dist = to_target.length()
		if dist > attack_range:
			var dir = to_target.normalized()
			velocity = dir * move_speed
			var target_rot = atan2(-dir.x, -dir.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rot, 8.0 * delta)
		else:
			velocity = Vector3.ZERO
			if attack_timer <= 0.0:
				_attack_target(target)
				
		move_and_slide()

func _find_target() -> Node3D:
	# Inimigos terrestres atacam paliçadas no caminho se estiverem muito perto, senão vão ao Rei
	if not is_flying:
		for palisade in get_tree().get_nodes_in_group("palisades"):
			if is_instance_valid(palisade) and global_position.distance_to(palisade.global_position) < 2.5:
				return palisade
	
	return GameState.king_node

func _attack_target(target: Node3D) -> void:
	attack_timer = 1.0 / attack_rate
	if target == GameState.king_node:
		GameState.damage_king(damage)
	elif target.has_method("take_damage"):
		target.take_damage(damage)

func take_damage(amount: int) -> void:
	if not alive:
		return
		
	current_hp -= amount
	AudioManager.play_sfx("hit")
	_spawn_damage_number(amount)
	
	if current_hp <= 0:
		_die()

func _spawn_damage_number(val: int) -> void:
	var float_scene = load("res://scenes/ui/FloatingNumber.tscn")
	if float_scene:
		var fn = float_scene.instantiate()
		get_parent().add_child(fn)
		fn.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 1.5, randf_range(-0.3, 0.3))
		fn.setup(val, Color(1.0, 0.9, 0.4))

func _die() -> void:
	alive = false
	GameState.unregister_enemy(self)
	died.emit(self)
	
	AudioManager.play_sfx("puff")
	_spawn_puff_effect()
	_drop_coins()
	queue_free()

func _spawn_puff_effect() -> void:
	# Nuvem cinza fofa ("puf")
	var puff_scene = load("res://scenes/entities/PuffEffect.tscn")
	if puff_scene:
		var p = puff_scene.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(0, 0.5, 0)

func _drop_coins() -> void:
	var coin_scene = load("res://scenes/entities/Coin.tscn")
	if not coin_scene:
		return
		
	for i in range(coin_drop_count):
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		var rand_offset = Vector3(randf_range(-0.7, 0.7), 0.2, randf_range(-0.7, 0.7))
		coin.global_position = global_position + rand_offset

