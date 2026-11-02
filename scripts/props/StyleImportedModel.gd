extends Node3D

# Aplica a mesma leitura toon aos modelos CC0 importados e preserva a hierarquia física da prop.

@export var fallback_color: Color = Color(0.52, 0.76, 0.20)

func _ready() -> void:
	call_deferred("_style_meshes", self)

func _style_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var color := fallback_color
			if child.mesh and child.mesh.get_surface_count() > 0:
				var source_material: Material = child.mesh.surface_get_material(0)
				if source_material is BaseMaterial3D:
					color = source_material.albedo_color
			child.material_override = Art.toon_mat(color, 0.82)
		if child.get_child_count() > 0:
			_style_meshes(child)
