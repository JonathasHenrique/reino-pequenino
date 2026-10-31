extends StaticBody3D

# Palisade.gd - Cerca/Paliçada de Madeira
# Bloqueia a passagem dos inimigos terrestres e absorve impacto

@export var max_hp: int = 220
var current_hp: int = 220
var alive: bool = true

@onready var hp_label: Label3D = $Label3D

func _ready() -> void:
	current_hp = max_hp
	add_to_group("palisades")
	_update_ui()

func take_damage(amount: int) -> void:
	if not alive:
		return
		
	current_hp = maxi(0, current_hp - amount)
	_update_ui()
	AudioManager.play_sfx("hit")
	
	if current_hp <= 0:
		_break_palisade()

func _update_ui() -> void:
	if hp_label:
		hp_label.text = "%d / %d" % [current_hp, max_hp]

func _break_palisade() -> void:
	alive = false
	AudioManager.play_sfx("puff")
	queue_free()

