extends Area3D

# Arrow.gd - Projétil de Flecha 3D disparado por arqueiros
# Voa em direção ao alvo e causa dano com número flutuante

@export var speed: float = 20.0
@export var damage: int = 12

var target_node: Node3D = null
var direction: Vector3 = Vector3.FORWARD
var life_time: float = 2.5

func _ready() -> void:
	for m in find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func setup(p_target: Node3D, p_damage: int, p_speed: float = 20.0) -> void:
	target_node = p_target
	damage = p_damage
	speed = p_speed
	if is_instance_valid(target_node):
		direction = (target_node.global_position + Vector3(0, 0.5, 0) - global_position).normalized()
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	life_time -= delta
	if life_time <= 0:
		queue_free()
		return
	
	if is_instance_valid(target_node):
		var to_target = (target_node.global_position + Vector3(0, 0.5, 0) - global_position)
		direction = to_target.normalized()
		look_at(global_position + direction, Vector3.UP)
		
		if to_target.length() <= speed * delta * 1.5:
			_hit_target()
			return
			
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body == target_node or body.is_in_group("enemies"):
		_hit_target()

func _hit_target() -> void:
	if is_instance_valid(target_node) and target_node.has_method("take_damage"):
		target_node.take_damage(damage)
	queue_free()

