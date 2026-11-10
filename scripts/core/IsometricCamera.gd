extends Camera3D

# IsometricCamera.gd - Câmera isométrica em ~50 graus com acompanhamento suave

@export var target_path: NodePath
@export var follow_speed: float = 6.0
@export var camera_distance: float = 23.4
@export var elevation_angle_deg: float = 48.0
@export var rotation_y_deg: float = 45.0
@export var follow_enabled: bool = true

var target_node: Node3D = null
var offset_vector: Vector3
var shake_remaining: float = 0.0
var shake_strength: float = 0.0
var custom_focus_active: bool = false
var custom_focus_point: Vector3 = Vector3.ZERO
var _pan_tween: Tween = null

func _ready() -> void:
	if not target_path.is_empty():
		target_node = get_node_or_null(target_path)
	
	# Calcula vetor de offset baseado no ângulo isométrico de 50° e rotação de 45°
	var elev_rad = deg_to_rad(elevation_angle_deg)
	var rot_rad = deg_to_rad(rotation_y_deg)
	
	var y = sin(elev_rad) * camera_distance
	var horizontal_dist = cos(elev_rad) * camera_distance
	var x = sin(rot_rad) * horizontal_dist
	var z = cos(rot_rad) * horizontal_dist
	
	offset_vector = Vector3(x, y, z)
	look_at_from_position(offset_vector, Vector3.ZERO, Vector3.UP)

func _physics_process(delta: float) -> void:
	if not follow_enabled:
		return
	if not target_node and GameState.king_node:
		target_node = GameState.king_node
		
	if target_node and is_instance_valid(target_node):
		var focus_pos: Vector3 = custom_focus_point if custom_focus_active else target_node.global_position
		var shake_offset := Vector3.ZERO
		if shake_remaining > 0.0:
			shake_remaining = maxf(0.0, shake_remaining - delta)
			var strength := shake_strength * (shake_remaining / 0.22)
			shake_offset = Vector3(randf_range(-strength, strength), randf_range(-strength, strength), 0.0)
		else:
			shake_strength = 0.0
		var target_pos = focus_pos + offset_vector + shake_offset
		var smooth := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(target_pos, smooth)
		look_at(focus_pos, Vector3.UP)

func pan_to_point(world_pos: Vector3, hold_duration: float = 1.5) -> void:
	if not target_node and GameState.king_node:
		target_node = GameState.king_node
	var start_pos: Vector3 = target_node.global_position if (target_node and is_instance_valid(target_node)) else Vector3.ZERO
	custom_focus_point = start_pos
	custom_focus_active = true
	if _pan_tween and _pan_tween.is_valid():
		_pan_tween.kill()
	_pan_tween = create_tween()
	_pan_tween.tween_property(self, "custom_focus_point", world_pos, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pan_tween.tween_interval(hold_duration)
	_pan_tween.tween_callback(func():
		var back_pos: Vector3 = target_node.global_position if (target_node and is_instance_valid(target_node)) else start_pos
		var back_tw := create_tween()
		back_tw.tween_property(self, "custom_focus_point", back_pos, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		back_tw.tween_callback(func(): custom_focus_active = false)
	)

func focus_instant_on(world_pos: Vector3) -> void:
	custom_focus_point = world_pos
	custom_focus_active = true
	global_position = world_pos + offset_vector
	look_at(world_pos, Vector3.UP)

func shake(strength: float = 0.12, duration: float = 0.22) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_remaining = maxf(shake_remaining, duration)
