extends Node3D

# VillagerBot.gd - Aldeão decorativo que passeia pela Vila (sem colisão nem combate).

@export var waypoints: Array = []
@export var speed: float = 1.15

var model: Node3D = null
var target: Vector3
var wait_time: float = 0.0
var bob_time: float = 0.0

func _ready() -> void:
	if waypoints.size() > 0:
		target = waypoints[randi() % waypoints.size()]

func _process(delta: float) -> void:
	if model == null:
		return
	bob_time += delta
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
		model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 6.0 * delta)
		model.position.y = abs(sin(bob_time * 7.0)) * 0.06
