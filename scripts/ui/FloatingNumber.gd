extends Node3D

# FloatingNumber.gd - Número de dano flutuante em 3D
# Sobe e esmaece suavemente ao acertar golpes

var velocity: Vector3 = Vector3(0, 2.2, 0)
var lifetime: float = 0.75
var initial_lifetime: float = 0.75

@onready var label: Label3D = $Label3D

func setup(number: int, color: Color = Color.WHITE) -> void:
	if not label:
		label = $Label3D
	label.text = "-%d" % number
	label.modulate = color

func _process(delta: float) -> void:
	lifetime -= delta
	position += velocity * delta
	
	if lifetime <= 0.0:
		queue_free()
	else:
		var alpha = lifetime / initial_lifetime
		label.modulate.a = alpha
