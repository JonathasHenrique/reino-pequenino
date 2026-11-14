extends Node3D

# EnemyArrow.gd - Flecha inimiga visível, com dano aplicado só no impacto.

var target_node: Node3D = null
var shooter: Node3D = null
var damage: int = 6
var speed: float = 13.0
var life_time: float = 3.0

func setup(p_target: Node3D, p_damage: int, p_shooter: Node3D = null) -> void:
	target_node = p_target
	damage = p_damage
	shooter = p_shooter

func _ready() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.12, 0.12)
	wood.emission_enabled = true
	wood.emission = Color(0.75, 0.15, 0.15)
	wood.emission_energy_multiplier = 0.7
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.07, 0.07, 0.8)
	shaft.mesh = box
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shaft.material_override = wood
	add_child(shaft)
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.1
	cone.height = 0.28
	tip.mesh = cone
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tip.material_override = wood
	tip.position = Vector3(0, 0, 0.48)
	tip.rotation = Vector3(PI * 0.5, 0, 0)
	add_child(tip)

func _physics_process(delta: float) -> void:
	life_time -= delta
	if life_time <= 0.0 or not is_instance_valid(target_node):
		queue_free()
		return
	var aim := target_node.global_position + Vector3(0, 0.9, 0) - global_position
	if aim.length() <= speed * delta * 1.6:
		_hit()
		return
	global_position += aim.normalized() * speed * delta
	if aim.length_squared() > 0.01:
		rotation.y = atan2(aim.x, aim.z)

func _hit() -> void:
	if is_instance_valid(target_node):
		if target_node == GameState.king_node:
			GameState.damage_king(damage, shooter)
		elif target_node.has_method("take_damage"):
			target_node.take_damage(damage)
	queue_free()
