extends Area3D

# Coin.gd - Moeda coletável por ímã magnético
# Flutua e gira suavemente no chão até ser atraída pelo Rei

@export var coin_value: int = 1
@export var float_speed: float = 3.5
@export var magnet_speed: float = 14.0

var is_being_attracted: bool = false
var target_king: Node3D = null
var current_accel: float = 1.0

@onready var visual_node: Node3D = $Visual

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("coins")

func _process(delta: float) -> void:
	if visual_node:
		visual_node.rotate_y(delta * 2.5)
	
	if is_being_attracted and is_instance_valid(target_king):
		var to_king = (target_king.global_position + Vector3(0, 0.6, 0)) - global_position
		var dist = to_king.length()
		
		current_accel += delta * 12.0
		var step = to_king.normalized() * (magnet_speed * current_accel * delta)
		var arc_y = sin(clampf(1.0 - (dist / 6.0), 0.0, 1.0) * PI) * 0.9
		if visual_node:
			visual_node.position.y = arc_y
		
		if step.length() >= dist or dist < 0.6:
			# Coleta concluída
			GameState.add_stage_coins(coin_value)
			_spawn_sparkle()
			queue_free()
		else:
			global_position += step

func _spawn_sparkle() -> void:
	if Settings.reduced_effects:
		return
	var sparkle_scene = load("res://scenes/entities/CoinSparkle.tscn")
	if sparkle_scene and get_parent():
		var sp = sparkle_scene.instantiate()
		get_parent().add_child(sp)
		sp.global_position = global_position

func attract_to(king: Node3D) -> void:
	if not is_being_attracted:
		is_being_attracted = true
		target_king = king
