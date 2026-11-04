extends StaticBody3D

# Palisade.gd - Cerca/Paliçada de Madeira
# Bloqueia a passagem dos inimigos terrestres e absorve impacto

const HealthBar3D = preload("res://scripts/entities/HealthBar3D.gd")

@export var max_hp: int = 220
var current_hp: int = 220
var alive: bool = true

var health_bar: MeshInstance3D = null

func _ready() -> void:
	current_hp = max_hp
	add_to_group("palisades")
	
	# Remove a label de texto poluída se existir
	var old_label = get_node_or_null("Label3D")
	if old_label:
		old_label.visible = false
		old_label.queue_free()
		
	# Barra de vida 3D limpa e moderna que só aparece quando sofre dano
	health_bar = HealthBar3D.create(self, 2.1, 1.8, Color(0.35, 0.85, 0.30), false)
	_update_ui()
	# Funde os troncos/vigas (estáticos) numa só malha por material.
	var visuals := get_node_or_null("Visuals") as Node3D
	if visuals:
		load("res://scripts/core/StaticMeshMerger.gd").merge_subtree(visuals)

func take_damage(amount: int) -> void:
	if not alive:
		return
		
	current_hp = maxi(0, current_hp - amount)
	_update_ui()
	AudioManager.play_sfx("hit")
	
	if current_hp <= 0:
		_break_palisade()

func _update_ui() -> void:
	if health_bar:
		health_bar.set_ratio(float(current_hp) / float(max_hp))

func repair_fully() -> void:
	current_hp = max_hp
	_update_ui()
	Art.pop_in(self)

func _break_palisade() -> void:
	alive = false
	AudioManager.play_sfx("puff")
	Art.dust_puff(get_parent(), global_position + Vector3(0, 1.0, 0), 10)
	queue_free()
