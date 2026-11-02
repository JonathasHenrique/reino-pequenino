extends Node3D

# FloatingNumber.gd - Número de dano flutuante estilo arcade (Kingshot / Clash)
# Sobe com um pulo elástico e esmaece suavemente

var velocity: Vector3 = Vector3(0, 3.2, 0)
var lifetime: float = 0.65
var initial_lifetime: float = 0.65

@onready var label: Label3D = $Label3D

func setup(number: int, color: Color = Color.WHITE) -> void:
	if not label:
		label = $Label3D
	label.text = "-%d" % number
	label.modulate = color
	scale = Vector3(0.4, 0.4, 0.4)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(1.15, 1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ONE, 0.1)
	velocity.x = randf_range(-0.8, 0.8)
	velocity.z = randf_range(-0.5, 0.5)

func _process(delta: float) -> void:
	lifetime -= delta
	position += velocity * delta
	velocity.y = maxf(1.0, velocity.y - 3.5 * delta) # desacelera suavemente
	
	if lifetime <= 0.0:
		queue_free()
	else:
		var alpha = lifetime / initial_lifetime
		if label:
			label.modulate.a = alpha
