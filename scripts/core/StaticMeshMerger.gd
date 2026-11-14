extends RefCounted

# StaticMeshMerger.gd - Funde malhas estáticas em poucos draw calls.
# Agrupa por material e gera uma única malha por grupo. Usado só em cenário
# decorativo (sem script de animação), nunca em personagens ou peças interativas.

static func merge_subtree(root: Node3D, exclude_names: Array = [], keep_shadows: bool = false, by_texture: bool = false) -> int:
	if root == null or not root.is_inside_tree():
		return 0
	var items: Array = []
	_collect(root, root, exclude_names, items)
	if items.size() < 2:
		return 0

	var groups: Dictionary = {}
	for item in items:
		var mi: MeshInstance3D = item["node"]
		var mesh: Mesh = mi.mesh
		for surface in range(mesh.get_surface_count()):
			var material: Material = mi.get_active_material(surface)
			if material == null:
				material = mesh.surface_get_material(surface)
			var key: int = _material_key(material, by_texture)
			if not groups.has(key):
				groups[key] = {"material": material, "parts": []}
			groups[key]["parts"].append({
				"mesh": mesh,
				"surface": surface,
				"transform": root.global_transform.affine_inverse() * mi.global_transform,
			})

	if groups.size() == 0:
		return 0

	var removed := 0
	for key in groups:
		var group: Dictionary = groups[key]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var appended := false
		for part in group["parts"]:
			st.append_from(part["mesh"], int(part["surface"]), part["transform"])
			appended = true
		if not appended:
			continue
		var merged: ArrayMesh = st.commit()
		if merged == null:
			continue
		var out := MeshInstance3D.new()
		out.name = "Merged_" + str(removed)
		out.mesh = merged
		out.material_override = group["material"]
		out.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if keep_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(out)
		removed += 1

	for item in items:
		var mi: MeshInstance3D = item["node"]
		mi.visible = false

	return items.size() - groups.size()

static func _material_key(material: Material, by_texture: bool) -> int:
	if material == null:
		return 0
	if by_texture and material is BaseMaterial3D:
		var tex := (material as BaseMaterial3D).albedo_texture
		if tex != null:
			return tex.get_instance_id()
	return material.get_instance_id()

static func _collect(root: Node3D, node: Node, exclude_names: Array, out: Array) -> void:
	for child in node.get_children():
		if exclude_names.has(str(child.name)):
			continue
		if child is Node3D and not (child as Node3D).visible:
			continue
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.mesh != null and mi.mesh.get_surface_count() > 0:
				out.append({"node": mi})
		if child.get_child_count() > 0:
			_collect(root, child, exclude_names, out)
