extends Node3D

# Aplica a mesma leitura toon aos modelos CC0 importados e preserva a hierarquia física da prop.

@export var fallback_color: Color = Color(0.52, 0.76, 0.20)
@export var albedo_texture: Texture2D
@export var tint: Color = Color.WHITE

func _ready() -> void:
	call_deferred("_style_meshes", self)

func set_tint(value: Color) -> void:
	tint = value
	_style_meshes(self)

func _style_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var color := Color.WHITE if albedo_texture else fallback_color
			if albedo_texture == null and child.mesh and child.mesh.get_surface_count() > 0:
				var source_material: Material = child.mesh.surface_get_material(0)
				if source_material is BaseMaterial3D:
					color = source_material.albedo_color
			color *= tint
			var toon_material := Art.toon_mat(color, 0.82)
			if albedo_texture and toon_material is ShaderMaterial:
				var textured_material := (toon_material as ShaderMaterial).duplicate() as ShaderMaterial
				textured_material.set_shader_parameter("albedo_texture", albedo_texture)
				textured_material.set_shader_parameter("use_albedo_texture", true)
				child.material_override = textured_material
			else:
				child.material_override = toon_material
		if child.get_child_count() > 0:
			_style_meshes(child)
