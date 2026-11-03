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
var base_tint: Color = Color(0.85, 0.21, 0.24)
var is_frozen: bool = false
var freeze_remaining: float = 0.0
var slow_remaining: float = 0.0
var slow_factor: float = 1.0
var knockback_remaining: float = 0.0
var knockback_velocity: Vector3 = Vector3.ZERO
var stuck_time: float = 0.0
var damage_flash_material: StandardMaterial3D
var flash_tween: Tween

@onready var visuals: Node3D = $Visuals
@onready var faction_ring: MeshInstance3D = $FactionRing

func _ready() -> void:
	damage_flash_material = StandardMaterial3D.new()
	damage_flash_material.albedo_color = Color.WHITE
	damage_flash_material.emission_enabled = true
	damage_flash_material.emission = Color.WHITE
	damage_flash_material.emission_energy_multiplier = 0.8
	damage_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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
	base_tint = tint
	if not visuals:
		visuals = $Visuals
	if visuals:
		visuals.scale = Vector3(scale_mult, scale_mult, scale_mult)
		_apply_enemy_tint(visuals, tint)
		
		if enemy_id == "misty_archer":
			_add_archer_gear(visuals)

		# Detalhes do Gigante Titã da Bruma (Capa vermelha fluida e capacete com chifres)
		if enemy_id == "misty_giant" or scale_mult >= 2.0:
			var cape = visuals.get_node_or_null("RedCape")
			if not cape:
				cape = MeshInstance3D.new()
				cape.name = "RedCape"
				var pm = PrismMesh.new()
				pm.size = Vector3(0.65, 0.95, 0.12)
				cape.mesh = pm
				cape.position = Vector3(0, 0.45, -0.32)
				cape.rotation = Vector3(0.25, PI, 0)
				var c_mat = StandardMaterial3D.new()
				c_mat.albedo_color = Color(0.85, 0.16, 0.14)
				c_mat.roughness = 0.8
				cape.material_override = c_mat
				visuals.add_child(cape)

func _add_archer_gear(parent: Node3D) -> void:
	# Silhueta de arqueira inimiga: capuz pontudo, arco na mão e aljava com penas.
	# Os nomes começam com "Gear_" para o tom da facção não recolorir estas peças.
	if parent.get_node_or_null("Gear_Hood"):
		return
	# O VisualUpgrade oculta filhos de Visuals que não estão em custom_overlays (troca diferida).
	var upgrade := get_node_or_null("VisualUpgrade")
	if upgrade:
		for gear_name in ["Gear_Hood", "Gear_Bow", "Gear_Quiver", "Gear_Feathers"]:
			if not upgrade.custom_overlays.has(gear_name):
				upgrade.custom_overlays.append(gear_name)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.36, 0.08, 0.12)
	cloth.roughness = 0.85
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.26, 0.14)
	wood.roughness = 0.8
	var feather := StandardMaterial3D.new()
	feather.albedo_color = Color(0.95, 0.85, 0.35)
	feather.roughness = 0.9

	var hood := MeshInstance3D.new()
	hood.name = "Gear_Hood"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 0.28
	cone.height = 0.45
	hood.mesh = cone
	hood.material_override = cloth
	hood.position = Vector3(0.0, 2.2, -0.02)
	hood.rotation = Vector3(-0.18, 0.0, 0.0)
	parent.add_child(hood)

	var bow := MeshInstance3D.new()
	bow.name = "Gear_Bow"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.44
	ring.outer_radius = 0.5
	bow.mesh = ring
	bow.material_override = wood
	bow.position = Vector3(0.62, 1.45, 0.05)
	bow.rotation = Vector3(0.0, 0.0, PI / 2.0)
	bow.rotation_degrees.y = 25.0
	parent.add_child(bow)

	var quiver := MeshInstance3D.new()
	quiver.name = "Gear_Quiver"
	var tube := CylinderMesh.new()
	tube.top_radius = 0.14
	tube.bottom_radius = 0.12
	tube.height = 0.9
	quiver.mesh = tube
	quiver.material_override = wood
	quiver.position = Vector3(-0.12, 1.85, -0.62)
	quiver.rotation = Vector3(0.28, 0.0, 0.18)
	parent.add_child(quiver)

	var fletch := MeshInstance3D.new()
	fletch.name = "Gear_Feathers"
	var plume := BoxMesh.new()
	plume.size = Vector3(0.2, 0.35, 0.04)
	fletch.mesh = plume
	fletch.material_override = feather
	fletch.position = Vector3(-0.12, 2.4, -0.66)
	fletch.rotation = Vector3(0.28, 0.0, 0.18)
	parent.add_child(fletch)

func _apply_enemy_tint(node: Node, tint: Color) -> void:
	for child in node.get_children():
		if str(child.name).begins_with("Gear_"):
			continue
		if child.has_method("set_tint"):
			child.set_tint(tint)
			continue
		if child is MeshInstance3D:
			child.material_override = Art.toon_mat(tint, 0.78)
		if child.get_child_count() > 0:
			_apply_enemy_tint(child, tint)

func freeze_for(duration: float) -> void:
	if not alive:
		return
	is_frozen = true
	freeze_remaining = maxf(freeze_remaining, duration)
	_apply_enemy_tint(visuals, Color(0.48, 0.82, 1.0))
	if faction_ring:
		var ice_material := StandardMaterial3D.new()
		ice_material.albedo_color = Color("#76DDF2")
		ice_material.emission_enabled = true
		ice_material.emission = Color("#76DDF2")
		ice_material.emission_energy_multiplier = 0.7
		ice_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		faction_ring.material_override = ice_material

func _clear_freeze() -> void:
	is_frozen = false
	freeze_remaining = 0.0
	_apply_enemy_tint(visuals, base_tint)
	if faction_ring:
		faction_ring.material_override = null

func apply_slow_for(duration: float, factor: float = 0.5) -> void:
	slow_remaining = maxf(slow_remaining, duration)
	slow_factor = minf(slow_factor, clampf(factor, 0.1, 1.0))

func knock_back_from(origin: Vector3, strength: float = 10.0) -> void:
	var direction := global_position - origin
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		return
	knockback_velocity = direction.normalized() * strength
	knockback_remaining = 0.25

func _exit_tree() -> void:
	GameState.unregister_enemy(self)

func is_alive() -> bool:
	return alive

func _physics_process(delta: float) -> void:
	if not alive or GameState.is_game_over:
		velocity = Vector3.ZERO
		return
	if is_frozen:
		freeze_remaining -= delta
		velocity = Vector3.ZERO
		if freeze_remaining <= 0.0:
			_clear_freeze()
		return
	if slow_remaining > 0.0:
		slow_remaining = maxf(0.0, slow_remaining - delta)
		if slow_remaining <= 0.0:
			slow_factor = 1.0
	if knockback_remaining > 0.0:
		knockback_remaining = maxf(0.0, knockback_remaining - delta)
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 32.0 * delta)
		move_and_slide()
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
			if stuck_time >= 0.25:
				var collision := get_last_slide_collision()
				if collision:
					var wall_normal := collision.get_normal()
					wall_normal.y = 0.0
					if wall_normal.length_squared() > 0.001:
						var tangent := Vector3.UP.cross(wall_normal).normalized()
						if tangent.dot(dir) < 0.0:
							tangent = -tangent
						dir = tangent
				stuck_time = 0.0
			velocity = dir * move_speed * slow_factor
			# Os visuais dos inimigos apontam para +Z.
			var target_rot = atan2(dir.x, dir.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rot, 8.0 * delta)
		else:
			velocity = Vector3.ZERO
			if attack_timer <= 0.0:
				_attack_target(target)
				
		move_and_slide()
		if velocity.length_squared() > 0.01 and get_position_delta().length_squared() < 0.0004:
			stuck_time += delta
		else:
			stuck_time = 0.0

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
	_flash_white_and_squash()
	
	if current_hp <= 0:
		_die()

func _flash_white_and_squash() -> void:
	if not visuals:
		return
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
	var meshes := visuals.find_children("*", "MeshInstance3D", true, false)
	var previous_overlays: Array[Material] = []
	for mesh in meshes:
		previous_overlays.append(mesh.material_overlay)
		mesh.material_overlay = damage_flash_material
	flash_tween = create_tween()
	flash_tween.tween_interval(0.06)
	flash_tween.tween_callback(func():
		for index in range(meshes.size()):
			var mesh := meshes[index] as MeshInstance3D
			if is_instance_valid(mesh):
				mesh.material_overlay = previous_overlays[index]
	)
	var orig_scale = visuals.scale
	visuals.scale = orig_scale * Vector3(1.25, 0.75, 1.25)
	var tw = create_tween()
	tw.tween_property(visuals, "scale", orig_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
	# Inimigo solta APENAS o capacete de bruma (o Rei deve levar ao Mercador Tobias para converter em moedas)
	_drop_spoils()
	queue_free()

func _drop_spoils() -> void:
	var spoil_scene = load("res://scenes/entities/SpoilLoot.tscn")
	if not spoil_scene:
		return
	var spoil = spoil_scene.instantiate()
	get_parent().add_child(spoil)
	spoil.global_position = global_position + Vector3(randf_range(-0.4, 0.4), 0.25, randf_range(-0.4, 0.4))

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
