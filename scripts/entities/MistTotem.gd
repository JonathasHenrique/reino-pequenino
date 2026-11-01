extends CharacterBody3D

# MistTotem.gd - Totem de Bruma Cinzenta
# O objetivo final da fase: destruí-lo limpa a névoa e garante a vitória!

const HealthBar3D = preload("res://scripts/entities/HealthBar3D.gd")

signal totem_destroyed()

@export var max_hp: int = 150
var current_hp: int = 150
var alive: bool = true
var is_shielded: bool = true

@onready var hp_label: Label3D = $Label3D
@onready var visuals: Node3D = $Visuals

var health_bar: MeshInstance3D = null
var shield_mesh: MeshInstance3D = null

func _ready() -> void:
	var stage_scale = pow(1.08, float(maxi(0, GameState.current_stage - 1)))
	current_hp = int(max_hp * stage_scale)
	max_hp = current_hp
	
	add_to_group("enemies")
	add_to_group("totems")
	GameState.totem_hp_changed.emit(current_hp, max_hp)
	
	# Cria cúpula visual de escudo de bruma translúcida
	_setup_shield_visual()
	
	# Barra de vida 3D acima do totem
	health_bar = HealthBar3D.create(self, 3.4, 2.4, Color(0.95, 0.35, 0.30), false)
	_update_ui()

func _setup_shield_visual() -> void:
	shield_mesh = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 1.6
	sm.height = 3.2
	shield_mesh.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.70, 0.95, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 0.9)
	mat.emission_energy_multiplier = 0.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shield_mesh.material_override = mat
	shield_mesh.position = Vector3(0, 1.4, 0)
	add_child(shield_mesh)

func _process(delta: float) -> void:
	if shield_mesh and is_shielded:
		shield_mesh.rotate_y(delta * 0.8)

func is_alive() -> bool:
	return alive

func remove_shield() -> void:
	is_shielded = false
	if shield_mesh:
		var tw = create_tween()
		tw.tween_property(shield_mesh, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
		tw.tween_callback(shield_mesh.queue_free)
		shield_mesh = null
	
	AudioManager.play_sfx("hero_skill")
	Art.dust_puff(get_parent(), global_position + Vector3(0, 1.5, 0), 20)
	_update_ui()
	if health_bar:
		health_bar.always_visible = true
		health_bar.visible = true

func take_damage(amount: int) -> void:
	if not alive:
		return
	if is_shielded:
		AudioManager.play_sfx("button_click")
		_spawn_damage_text("🛡️ BLINDADO")
		return
		
	current_hp = maxi(0, current_hp - amount)
	GameState.totem_hp_changed.emit(current_hp, max_hp)
	_update_ui()
	_spawn_damage_number(amount)
	AudioManager.play_sfx("hit")
	
	if current_hp <= 0:
		_destroy_totem()

func _update_ui() -> void:
	if health_bar:
		health_bar.set_ratio(float(current_hp) / float(max_hp))
	
	if hp_label:
		if is_shielded:
			hp_label.text = "🛡️ BRUMA PROTETORA"
			hp_label.modulate = Color(0.7, 0.85, 1.0)
		else:
			hp_label.text = "⚔️ TOTEM VULNERÁVEL!"
			hp_label.modulate = Color(1.0, 0.45, 0.45)

func _spawn_damage_text(msg: String) -> void:
	var float_scene = load("res://scenes/ui/FloatingNumber.tscn")
	if float_scene:
		var fn = float_scene.instantiate()
		get_parent().add_child(fn)
		fn.global_position = global_position + Vector3(0, 3.2, 0)
		fn.setup(0, Color(0.8, 0.8, 0.9))
		var l = fn.get_node_or_null("Label3D")
		if l:
			l.text = msg

func _spawn_damage_number(val: int) -> void:
	var float_scene = load("res://scenes/ui/FloatingNumber.tscn")
	if float_scene:
		var fn = float_scene.instantiate()
		get_parent().add_child(fn)
		fn.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 3.2, randf_range(-0.5, 0.5))
		fn.setup(val, Color(1.0, 0.4, 0.4))

func _destroy_totem() -> void:
	alive = false
	totem_destroyed.emit()
	AudioManager.play_sfx("puff")
	Art.dust_puff(get_parent(), global_position + Vector3(0, 1.5, 0), 30)
	
	# Chuva comemorativa de moedas na destruição final do totem!
	var coin_scene = load("res://scenes/entities/Coin.tscn")
	if coin_scene:
		for i in range(16):
			var c = coin_scene.instantiate()
			get_parent().add_child(c)
			c.global_position = global_position + Vector3(randf_range(-2.0, 2.0), 0.3, randf_range(-2.0, 2.0))
			if c.has_method("attract_to") and GameState.king_node:
				c.attract_to(GameState.king_node)
	
	GameState.complete_stage(true)
	queue_free()
