extends CharacterBody3D

# FollowerTroop.gd - Classe base para tropas leais que seguem o Rei
# Implementa formação ao redor do Rei, separação e mira automática

@export var troop_id: String = "archer"
@export var move_speed: float = 6.8
@export var attack_range: float = 8.5
@export var attack_rate: float = 1.1 # Disparos por segundo
@export var base_damage: int = 12
@export var hp: int = 35

const TARGET_SEARCH_INTERVAL: float = 0.18
const ARROW_SCENE: PackedScene = preload("res://scenes/entities/Arrow.tscn")
const BOW_SCENE: PackedScene = preload("res://assets/models/chibi/bow.gltf")

var current_hp: int = 35
var is_mounted_on_tower: bool = false
var mounted_tower_node: Node3D = null
var attack_cooldown: float = 0.0
var target_search_timer: float = 0.0
var current_target: Node3D = null
var walk_time: float = 0.0

@onready var visuals: Node3D = $Visuals

var _base_visual_scale: Vector3 = Vector3.ONE
var _chibi: bool = false

func _ready() -> void:
	current_hp = hp
	target_search_timer = randf_range(0.0, TARGET_SEARCH_INTERVAL)
	add_to_group("troops")
	# Camada própria (bit 3): o Rei atravessa aliados; mundo/paliçadas continuam bloqueando.
	collision_layer = 8
	GameState.register_troop(self)
	if troop_id == "archer":
		_chibi = true
		var old_visuals := visuals
		if old_visuals:
			old_visuals.visible = false
		var chibi: Node3D = load("res://scripts/effects/ChibiModel.gd").spawn(self, "rogue_hooded", 2.08, Color.WHITE, false, false)
		if chibi:
			visuals = chibi
			_add_bow(chibi)
			if old_visuals and old_visuals != visuals:
				old_visuals.queue_free()
	else:
		visuals.scale *= 0.85
		var imported := visuals.get_node_or_null("ImportedCharacter") as Node3D
		if imported:
			load("res://scripts/effects/ChibiFace.gd").attach(imported, false, Color(0.16, 0.32, 0.20))
	_base_visual_scale = visuals.scale
	_disable_shadows_recursive(self)
	
	# Bônus do Quartel da Vila
	var barracks_lvl = SaveManager.save_data.get("village_buildings", {}).get("barracks", 1)
	base_damage = int(base_damage * (1.0 + (barracks_lvl - 1) * 0.1))
	
	# Bônus passivo do Mago Fidélio (+10% de dano)
	if SaveManager.save_data.get("selected_hero") == "fidelio":
		base_damage = int(base_damage * 1.10)

func _disable_shadows_recursive(node: Node) -> void:
	for m in node.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _add_bow(parent: Node3D) -> void:
	if BOW_SCENE == null:
		return
	var holder := Node3D.new()
	holder.position = Vector3(0.55, 1.10, 0.18)
	parent.add_child(holder)
	var bow := BOW_SCENE.instantiate() as Node3D
	holder.add_child(bow)
	bow.rotation.x = -PI * 0.5
	bow.scale = Vector3.ONE * 0.72
	var box := AABB()
	var first := true
	for m in bow.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var xf: Transform3D = holder.global_transform.affine_inverse() * mi.global_transform
		var a: AABB = xf * mi.get_aabb()
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	bow.position -= box.get_center()

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
		var squash := absf(sin(walk_time))
		visuals.scale = _base_visual_scale * Vector3(1.0 - 0.05 * squash, 1.0 + 0.08 * squash, 1.0 - 0.05 * squash)
		
		# Rotação para a direção do movimento
		var target_rot = atan2(dir.x, dir.z) + (0.0 if _chibi else PI)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rot, 10.0 * delta)
	else:
		velocity = Vector3.ZERO
		visuals.position.y = lerp(visuals.position.y, 0.0, 10.0 * delta)
		visuals.rotation.z = lerp(visuals.rotation.z, 0.0, 10.0 * delta)
		var breathe := sin(Time.get_ticks_msec() * 0.0025)
		visuals.scale = _base_visual_scale * Vector3(1.0, 1.0 + breathe * 0.02, 1.0)
		
	move_and_slide()

func _handle_combat(delta: float) -> void:
	# Busca inimigo mais próximo a cada TARGET_SEARCH_INTERVAL (evita varrer grupos a cada frame)
	target_search_timer -= delta
	if target_search_timer <= 0.0 or not is_instance_valid(current_target) or (current_target.has_method("is_alive") and not current_target.is_alive()):
		if target_search_timer <= 0.0:
			target_search_timer = TARGET_SEARCH_INTERVAL
			current_target = _find_nearest_enemy(attack_range)
		else:
			current_target = null
	
	if current_target and is_instance_valid(current_target):
		# Vira na direção do alvo
		var to_enemy = current_target.global_position - global_position
		to_enemy.y = 0
		if to_enemy.length_squared() > 0.01:
			var target_rot = atan2(to_enemy.x, to_enemy.z) + (0.0 if _chibi else PI)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rot, 14.0 * delta)
			
		if attack_cooldown <= 0.0:
			_perform_attack(current_target)

func _handle_mounted_combat(delta: float) -> void:
	var extended_range = attack_range * 1.35
	target_search_timer -= delta
	if target_search_timer <= 0.0 or not is_instance_valid(current_target) or (current_target.has_method("is_alive") and not current_target.is_alive()):
		if target_search_timer <= 0.0:
			target_search_timer = TARGET_SEARCH_INTERVAL
			current_target = _find_nearest_enemy(extended_range)
		else:
			current_target = null
	
	if current_target and is_instance_valid(current_target):
		var to_enemy = current_target.global_position - global_position
		to_enemy.y = 0
		if to_enemy.length_squared() > 0.01:
			visuals.rotation.y = atan2(to_enemy.x, to_enemy.z) + (0.0 if _chibi else PI)
			
		if attack_cooldown <= 0.0:
			_perform_attack(current_target, 1.25)

func _perform_attack(target: Node3D, damage_multiplier: float = 1.0) -> void:
	# Velocidade de ataque acelerada se habilidade do Teodoro estiver ativa
	var speed_mult = 1.3 if GameState.hero_ability_active else 1.0
	attack_cooldown = (1.0 / (attack_rate * speed_mult))
	if troop_id == "archer":
		_animate_archer_attack()
	
	AudioManager.play_sfx("shoot")
	_spawn_arrow(target, int(base_damage * damage_multiplier))

func _animate_archer_attack() -> void:
	var arm := visuals.get_node_or_null("ArmR") as MeshInstance3D
	var bow := visuals.get_node_or_null("ArmL/Bow") as MeshInstance3D
	if not arm or not bow:
		return

	var arm_rest := arm.rotation.z
	var bow_rest := bow.rotation.z
	var tween := create_tween()
	tween.tween_property(arm, "rotation:z", arm_rest + 0.45, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(bow, "rotation:z", bow_rest - 0.18, 0.09)
	tween.tween_property(arm, "rotation:z", arm_rest, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(bow, "rotation:z", bow_rest, 0.12)

func _spawn_arrow(target: Node3D, dmg: int) -> void:
	if ARROW_SCENE:
		var arrow = ARROW_SCENE.instantiate()
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

var _buff_ring: MeshInstance3D = null
var _buff_tween: Tween = null

func take_damage(amount: int) -> void:
	var final_amount := amount
	# Passiva da Capitã Rosa: tropas aliadas recebem 15% menos dano
	if SaveManager.save_data.get("selected_hero") == "rosa":
		final_amount = maxi(1, int(float(amount) * 0.85))
	current_hp = maxi(0, current_hp - final_amount)
	if current_hp <= 0:
		queue_free()

func apply_hero_buff(buff_color: Color, duration: float, label_text: String) -> void:
	if not is_inside_tree():
		return
		
	# 1. Floating text subindo da tropa
	if label_text != "":
		var floating := Art.label(get_parent(), label_text, global_position + Vector3(0, 2.3, 0), 50, buff_color)
		if floating:
			var tw := floating.create_tween()
			tw.tween_property(floating, "position:y", floating.position.y + 1.8, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(floating, "modulate:a", 0.0, 1.2)
			tw.tween_callback(floating.queue_free)
			
	# 2. Material overlay emissivo evidente nas malhas da tropa
	var overlay_mat := StandardMaterial3D.new()
	overlay_mat.albedo_color = Color(buff_color.r, buff_color.g, buff_color.b, 0.50)
	overlay_mat.emission_enabled = true
	overlay_mat.emission = buff_color
	overlay_mat.emission_energy_multiplier = 2.4
	overlay_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	for m in visuals.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_overlay = overlay_mat
		
	# 3. Anel luminoso pulsante nos pés da tropa
	if _buff_ring and is_instance_valid(_buff_ring):
		_buff_ring.queue_free()
		_buff_ring = null
		
	_buff_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.80
	_buff_ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(buff_color.r, buff_color.g, buff_color.b, 0.88)
	ring_mat.emission_enabled = true
	ring_mat.emission = buff_color
	ring_mat.emission_energy_multiplier = 2.8
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_buff_ring.material_override = ring_mat
	_buff_ring.position = Vector3(0, 0.08, 0)
	add_child(_buff_ring)
	
	if _buff_tween and _buff_tween.is_valid():
		_buff_tween.kill()
		
	_buff_tween = create_tween()
	_buff_tween.tween_interval(maxf(0.1, duration - 1.2))
	_buff_tween.tween_property(overlay_mat, "albedo_color:a", 0.0, 1.2)
	if _buff_ring:
		_buff_tween.parallel().tween_property(ring_mat, "albedo_color:a", 0.0, 1.2)
	_buff_tween.tween_callback(func():
		for m in visuals.find_children("*", "MeshInstance3D", true, false):
			if (m as MeshInstance3D).material_overlay == overlay_mat:
				(m as MeshInstance3D).material_overlay = null
		if _buff_ring and is_instance_valid(_buff_ring):
			_buff_ring.queue_free()
			_buff_ring = null
	)
