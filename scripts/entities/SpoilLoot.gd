extends Area3D

# SpoilLoot.gd - Sucata de Batalha / Capacetes dos Inimigos Derrotados
# Coletável por ímã e vendido no Balcão do Mercador para obter moedas

@export var value: int = 1
@export var attract_speed: float = 14.0

var is_attracted: bool = false
var target_node: Node3D = null
var bob_time: float = 0.0

@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	add_to_group("spoils")
	add_to_group("coins") # Permite que a área de ímã do Rei também atraia o loot!
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	bob_time += delta * 4.0
	if visuals:
		visuals.rotation.y += delta * 2.5
		visuals.position.y = 0.25 + sin(bob_time) * 0.08
		
	if is_attracted and is_instance_valid(target_node):
		var target_pos = target_node.global_position + Vector3(0, 0.6, 0)
		var to_target = target_pos - global_position
		var dist = to_target.length()
		var arc_y = sin(clampf(1.0 - (dist / 6.0), 0.0, 1.0) * PI) * 1.1
		global_position = global_position.move_toward(target_pos, attract_speed * delta)
		if visuals:
			visuals.position.y = 0.25 + arc_y
		if global_position.distance_to(target_pos) < 0.8:
			_collect()

func attract_to(target: Node3D) -> void:
	is_attracted = true
	target_node = target

func _on_body_entered(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		_collect()

func _collect() -> void:
	GameState.add_stage_spoils(value)
	AudioManager.play_sfx("coin_pickup")
	
	# Texto flutuante mostrando a coleta do capacete
	var float_scene = load("res://scenes/ui/FloatingNumber.tscn")
	if float_scene:
		var fn = float_scene.instantiate()
		get_parent().add_child(fn)
		fn.global_position = global_position + Vector3(0, 1.2, 0)
		fn.setup(value, Color(1.0, 0.4, 0.4))
		
	queue_free()

