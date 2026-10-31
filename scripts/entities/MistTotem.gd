extends CharacterBody3D

# MistTotem.gd - Totem de Bruma Cinzenta
# O objetivo final da fase: destruí-lo limpa a névoa e garante a vitória!

signal totem_destroyed()

@export var max_hp: int = 150
var current_hp: int = 150
var alive: bool = true
var is_shielded: bool = true

@onready var hp_label: Label3D = $Label3D
@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	# Ajusta HP conforme a fase
	var stage_scale = pow(1.08, float(maxi(0, GameState.current_stage - 1)))
	current_hp = int(max_hp * stage_scale)
	max_hp = current_hp
	
	add_to_group("enemies")
	add_to_group("totems")
	GameState.totem_hp_changed.emit(current_hp, max_hp)
	_update_ui()

func is_alive() -> bool:
	return alive

func remove_shield() -> void:
	is_shielded = false
	_update_ui()
	AudioManager.play_sfx("hero_skill")

func take_damage(amount: int) -> void:
	if not alive:
		return
	if is_shielded:
		# Escudo de Bruma bloqueia dano enquanto as ondas estiverem ativas
		AudioManager.play_sfx("button_click")
		_spawn_damage_text("BLINDADO!")
		return
		
	current_hp = maxi(0, current_hp - amount)
	GameState.totem_hp_changed.emit(current_hp, max_hp)
	_update_ui()
	_spawn_damage_number(amount)
	AudioManager.play_sfx("hit")
	
	if current_hp <= 0:
		_destroy_totem()

func _update_ui() -> void:
	if hp_label:
		if is_shielded:
			hp_label.text = "🛡️ BRUMA PROTETORA!\n(Derrote as ondas primeiro)"
			hp_label.modulate = Color(0.9, 0.95, 1.0)
		else:
			hp_label.text = "⚔️ TOTEM VULNERÁVEL!\n[HP: %d / %d]" % [current_hp, max_hp]
			hp_label.modulate = Color(1.0, 0.5, 0.5)

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
	
	# Chuva de moedas da vitória
	var coin_scene = load("res://scenes/entities/Coin.tscn")
	if coin_scene:
		for i in range(12):
			var c = coin_scene.instantiate()
			get_parent().add_child(c)
			c.global_position = global_position + Vector3(randf_range(-1.8, 1.8), 0.3, randf_range(-1.8, 1.8))
	
	# Notifica vitória do estágio
	GameState.complete_stage(true)
	queue_free()

