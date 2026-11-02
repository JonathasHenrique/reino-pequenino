extends CharacterBody3D

# FollowerTroop.gd - Classe base para tropas leais que seguem o Rei
# Implementa formação ao redor do Rei, separação e mira automática

@export var troop_id: String = "archer"
@export var move_speed: float = 6.8
@export var attack_range: float = 8.5
@export var attack_rate: float = 1.1 # Disparos por segundo
@export var base_damage: int = 12
@export var hp: int = 35

var current_hp: int = 35
var is_mounted_on_tower: bool = false
var mounted_tower_node: Node3D = null
var attack_cooldown: float = 0.0
var current_target: Node3D = null
var walk_time: float = 0.0

@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	current_hp = hp
	add_to_group("troops")
	GameState.register_troop(self)
	
	# Bônus do Quartel da Vila
	var barracks_lvl = SaveManager.save_data.get("village_buildings", {}).get("barracks", 1)
	base_damage = int(base_damage * (1.0 + (barracks_lvl - 1) * 0.1))

func _exit_tree() -> void:
	GameState.unregister_troop(self)

func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		return
		
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	
	if is_mounted_on_tower:
		# Posicionado na torre de vigia, ataca de cima com alcance e dano ampliados
		_handle_mounted_combat(delta)
	else:
		_handle_formation_movement(delta)
		_handle_combat(delta)

func _handle_formation_movement(delta: float) -> void:
	if not GameState.king_node or not is_instance_valid(GameState.king_node):
		return
		
	var my_index = GameState.active_troops.find(self)
	if my_index == -1:
		my_index = 0
		
	var target_pos = GameState.king_node.get_formation_position(my_index, GameState.active_troops.size())
	var to_target = target_pos - global_position
	to_target.y = 0
	
	if to_target.length() > 0.4:
		var dir = to_target.normalized()
		velocity = dir * move_speed
		
		# Animação de caminhada com balanço fofo
		walk_time += delta * 14.0
		visuals.position.y = abs(sin(walk_time)) * 0.10
		visuals.rotation.z = sin(walk_time) * 0.08
		
		# Rotação para a direção do movimento
		var target_rot = atan2(dir.x, dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rot, 10.0 * delta)
	else:
		velocity = Vector3.ZERO
		visuals.position.y = lerp(visuals.position.y, 0.0, 10.0 * delta)
		visuals.rotation.z = lerp(visuals.rotation.z, 0.0, 10.0 * delta)
		
	move_and_slide()

func _handle_combat(_delta: float) -> void:
	# Busca inimigo mais próximo dentro do raio de ataque
	current_target = _find_nearest_enemy(attack_range)
	
	if current_target and is_instance_valid(current_target):
		# Vira na direção do alvo
		var to_enemy = current_target.global_position - global_position
		to_enemy.y = 0
		if to_enemy.length_squared() > 0.01:
			var target_rot = atan2(to_enemy.x, to_enemy.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rot, 14.0 * _delta)
			
		if attack_cooldown <= 0.0:
			_perform_attack(current_target)

func _handle_mounted_combat(_delta: float) -> void:
	var extended_range = attack_range * 1.35
	current_target = _find_nearest_enemy(extended_range)
	
	if current_target and is_instance_valid(current_target):
		var to_enemy = current_target.global_position - global_position
		to_enemy.y = 0
		if to_enemy.length_squared() > 0.01:
			visuals.rotation.y = atan2(to_enemy.x, to_enemy.z)
			
		if attack_cooldown <= 0.0:
			_perform_attack(current_target, 1.25)

func _perform_attack(target: Node3D, damage_multiplier: float = 1.0) -> void:
	# Velocidade de ataque acelerada se habilidade do Teodoro estiver ativa
	var speed_mult = 1.3 if GameState.hero_ability_active else 1.0
	attack_cooldown = (1.0 / (attack_rate * speed_mult))
	
	AudioManager.play_sfx("shoot")
	_spawn_arrow(target, int(base_damage * damage_multiplier))

func _spawn_arrow(target: Node3D, dmg: int) -> void:
	var arrow_scene = load("res://scenes/entities/Arrow.tscn")
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		get_parent().add_child(arrow)
		arrow.global_position = global_position + Vector3(0, 0.8, 0)
		arrow.setup(target, dmg)

func _find_nearest_enemy(max_dist: float) -> Node3D:
	var nearest: Node3D = null
	var min_dist = max_dist
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.is_alive():
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = enemy
				
	return nearest

func mount_on_tower(tower: Node3D, mount_position: Vector3) -> void:
	is_mounted_on_tower = true
	mounted_tower_node = tower
	global_position = mount_position
	velocity = Vector3.ZERO
