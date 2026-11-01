extends Camera3D

# IsometricCamera.gd - Câmera isométrica em ~50 graus com acompanhamento suave

@export var target_path: NodePath
@export var follow_speed: float = 6.0
@export var camera_distance: float = 17.5
@export var elevation_angle_deg: float = 48.0
@export var rotation_y_deg: float = 45.0

var target_node: Node3D = null
var offset_vector: Vector3

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
	if not target_node and GameState.king_node:
		target_node = GameState.king_node
		
	if target_node and is_instance_valid(target_node):
		var target_pos = target_node.global_position + offset_vector
		global_position = global_position.lerp(target_pos, follow_speed * delta)
		look_at(target_node.global_position, Vector3.UP)

