extends Node3D

@export var lifetime: float = 0.5

var follow_target: Node3D
var follow_offset: Vector3 = Vector3.ZERO
var elapsed: float = 0.0

func follow(target: Node3D, offset: Vector3 = Vector3.ZERO) -> void:
	follow_target = target
	follow_offset = offset
	if is_instance_valid(follow_target):
		global_position = follow_target.global_position + follow_offset

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(follow_target):
		global_position = follow_target.global_position + follow_offset
	else:
		position.y += delta * 1.5
	scale += Vector3.ONE * delta * 2.0
	if elapsed >= lifetime:
		queue_free()