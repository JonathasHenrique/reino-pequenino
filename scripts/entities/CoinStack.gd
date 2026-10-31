extends Node3D

# CoinStack.gd - Representação visual da coluna de moedas sobre o Rei/Pônei
# As moedas empilham verticalmente conforme o jogador recolhe recursos

@export var coin_thickness: float = 0.08
@export var max_rendered_coins: int = 35 # Limite visual para manter 60 fps
@export var coin_radius: float = 0.35

var rendered_count: int = 0
var mesh_instances: Array[MeshInstance3D] = []
var coin_cylinder_mesh: CylinderMesh
var coin_material: StandardMaterial3D

func _ready() -> void:
	_setup_mesh_and_material()
	GameState.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.stage_coins)

func _setup_mesh_and_material() -> void:
	coin_cylinder_mesh = CylinderMesh.new()
	coin_cylinder_mesh.top_radius = coin_radius
	coin_cylinder_mesh.bottom_radius = coin_radius
	coin_cylinder_mesh.height = coin_thickness
	
	coin_material = StandardMaterial3D.new()
	coin_material.albedo_color = Color(1.0, 0.82, 0.15) # Ouro brilhante de brinquedo
	coin_material.roughness = 0.25
	coin_material.metallic = 0.75

func _on_coins_changed(new_amount: int) -> void:
	# Mapeamento do número de moedas para quantidade de discos visuais
	var target_render = mini(new_amount, max_rendered_coins)
	
	while mesh_instances.size() < target_render:
		var inst = MeshInstance3D.new()
		inst.mesh = coin_cylinder_mesh
		inst.material_override = coin_material
		inst.position = Vector3(0, mesh_instances.size() * (coin_thickness + 0.01), 0)
		add_child(inst)
		mesh_instances.append(inst)
		
	while mesh_instances.size() > target_render:
		var last = mesh_instances.pop_back()
		last.queue_free()

