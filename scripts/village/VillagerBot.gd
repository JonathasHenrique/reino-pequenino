extends Node3D

# VillagerBot.gd - Aldeão decorativo que passeia pela Vila (sem colisão nem combate).

@export var waypoints: Array = []
@export var speed: float = 1.15

var model: Node3D = null
var target: Vector3
var wait_time: float = 0.0
var bob_time: float = 0.0
var _base_model_scale: Vector3 = Vector3.ZERO

func _ready() -> void:
	if waypoints.size() > 0:
		target = waypoints[randi() % waypoints.size()]

func _process(delta: float) -> void:
	if model == null:
		return
	if _base_model_scale == Vector3.ZERO:
		_base_model_scale = model.scale
		load("res://scripts/effects/ChibiFace.gd").attach(model, false)
	bob_time += delta
	var bounce := absf(sin(bob_time * 7.0))
	model.scale = _base_model_scale * Vector3(1.0 - 0.04 * bounce, 1.0 + 0.06 * bounce, 1.0 - 0.04 * bounce)
	if wait_time > 0.0:
		wait_time -= delta
		model.position.y = sin(bob_time * 2.0) * 0.02
		return
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.25:
		wait_time = randf_range(0.8, 2.6)
		if waypoints.size() > 0:
			target = waypoints[randi() % waypoints.size()]
		return
	var dir := to.normalized()
	global_position += dir * speed * delta
	if model:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z) + PI, 6.0 * delta)
		model.position.y = abs(sin(bob_time * 7.0)) * 0.06
