extends Node3D

# SpoilStack.gd - Representação visual da pilha de capacetes/sucata carregada pelo Rei
# Mostra os capacetes vermelhos/cinzentos coletados empilhados no alforje do pônei

@export var helmet_thickness: float = 0.12
@export var max_rendered_helmets: int = 25
@export var helmet_radius: float = 0.28

var mesh_instances: Array[MeshInstance3D] = []
var helmet_mesh: SphereMesh
var helmet_material: StandardMaterial3D

func _ready() -> void:
	_setup_mesh_and_material()
	if GameState.has_signal("spoils_changed"):
		GameState.spoils_changed.connect(_on_spoils_changed)
	_on_spoils_changed(GameState.stage_spoils)

func _setup_mesh_and_material() -> void:
	helmet_mesh = SphereMesh.new()
	helmet_mesh.radius = helmet_radius
	helmet_mesh.height = helmet_thickness * 2.0
	
	helmet_material = StandardMaterial3D.new()
	helmet_material.albedo_color = Color(0.85, 0.25, 0.22) # Vermelho carmesim dos inimigos de bruma
	helmet_material.metallic = 0.5
	helmet_material.roughness = 0.4

func _on_spoils_changed(new_amount: int) -> void:
	var target_render = mini(new_amount, max_rendered_helmets)
	
	while mesh_instances.size() < target_render:
		var inst = MeshInstance3D.new()
		inst.mesh = helmet_mesh
		inst.material_override = helmet_material
		# Pequena variação lateral e rotação para parecer uma pilha empilhada real
		var y_pos = mesh_instances.size() * helmet_thickness
		var wobble_x = sin(mesh_instances.size() * 1.5) * 0.03
		inst.position = Vector3(wobble_x, y_pos, 0)
		add_child(inst)
		mesh_instances.append(inst)
		
	while mesh_instances.size() > target_render:
		var last = mesh_instances.pop_back()
		last.queue_free()
