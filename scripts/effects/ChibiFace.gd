extends RefCounted

# ChibiFace.gd - Rosto billboard (sempre de frente para a câmera) estilo brinquedo.
# Funciona em qualquer modelo CC0 sem depender da orientação da malha.

static var _cache: Dictionary = {}

static func attach(model: Node3D, angry: bool = false, _hair_color: Color = Color(0.27, 0.17, 0.11)) -> void:
	if model == null or not model.is_inside_tree():
		return
	if model.get_node_or_null("Face_Root") != null:
		return
	var box := _bounds(model)
	if box.size.y < 0.05:
		return
	var h := box.size.y
	var info := _head_info(model, box)
	var center: Vector3 = info["center"]
	var root := Node3D.new()
	root.name = "Face_Root"
	root.position = Vector3(center.x, box.position.y + h * 0.80, center.z - h * 0.004)
	model.add_child(root)

	var dark := _mat(Color(0.11, 0.08, 0.07), 0.55)
	var glint := _mat(Color(1, 1, 1), 1.0, true)
	var brow_mat := _mat(Color(0.24, 0.15, 0.10), 0.8)
	var mouth_mat := _mat(Color(0.34, 0.10, 0.10), 0.7)

	var eye_r := h * 0.026
	var eye_x := h * 0.053
	var eye_z := -h * 0.006
	for sx in [-1.0, 1.0]:
		var eye := _sphere(root, eye_r, Vector3(sx * eye_x, 0.0, eye_z), dark)
		eye.scale = Vector3(1.0, 1.18, 0.6)
		_sphere(root, eye_r * 0.34, Vector3(sx * eye_x - eye_r * 0.32, eye_r * 0.34, eye_z - eye_r * 0.52), glint)
		var brow := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(h * 0.068, h * 0.012, h * 0.014)
		brow.mesh = bm
		brow.material_override = brow_mat
		brow.position = Vector3(sx * eye_x, eye_r * 1.9, eye_z)
		brow.rotation.z = (-0.30 if angry else 0.0) * sx
		root.add_child(brow)

	if angry:
		var mouth := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(h * 0.05, h * 0.009, h * 0.012)
		mouth.mesh = mm
		mouth.material_override = mouth_mat
		mouth.position = Vector3(0, -h * 0.050, eye_z)
		root.add_child(mouth)
	else:
		for i in range(5):
			var t := (float(i) - 2.0) / 2.0
			var my := -h * 0.045 + t * t * h * 0.010
			_sphere(root, h * 0.0055, Vector3(t * h * 0.030, my, eye_z), mouth_mat)

	load("res://scripts/core/StaticMeshMerger.gd").merge_subtree(root, [], false, false)
	for child in root.get_children():
		if str(child.name).begins_with("Merged_"):
			child.name = "Face_" + str(child.name)

static func _sphere(parent: Node3D, radius: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	mi.mesh = sphere
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _mat(color: Color, roughness: float, unshaded: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.0
	return m

static func _face_material(angry: bool) -> StandardMaterial3D:
	var key := "angry" if angry else "happy"
	var tex: ImageTexture
	if _cache.has(key):
		tex = _cache[key]
	else:
		tex = _face_texture(angry)
		_cache[key] = tex
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = 0.2
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return m

static func _face_texture(angry: bool) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var white := Color(1, 1, 1, 1)
	var dark := Color(0.10, 0.07, 0.06, 1)
	var brow_col := Color(0.28, 0.17, 0.12, 1)
	for eye in [Vector2(23, 30), Vector2(41, 30)]:
		_ellipse(img, eye, 7.0, 7.8, white)
		_ellipse(img, eye + Vector2(0, 0.6), 3.9, 4.4, dark)
		_disc(img, eye + Vector2(-1.8, -2.0), 1.3, white)
	_line(img, Vector2(14, 19), Vector2(28, 16 if angry else 17), brow_col, 2.4)
	_line(img, Vector2(50, 19), Vector2(36, 16 if angry else 17), brow_col, 2.4)
	if angry:
		_line(img, Vector2(26, 45), Vector2(38, 45), dark, 2.2)
	else:
		for x in range(26, 39):
			var t := (x - 32) / 13.0
			var y := 43 + int((1.0 - t * t) * 3.0)
			_disc(img, Vector2(x, y), 1.4, dark)
	return ImageTexture.create_from_image(img)

static func _ellipse(img: Image, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var ix := int(ceil(rx))
	var iy := int(ceil(ry))
	for x in range(-ix, ix + 1):
		for y in range(-iy, iy + 1):
			var d := Vector2(x / rx, y / ry).length()
			if d <= 1.0:
				var px := int(center.x) + x
				var py := int(center.y) + y
				if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
					img.set_pixel(px, py, color)

static func _soft_ellipse(img: Image, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var ix := int(ceil(rx))
	var iy := int(ceil(ry))
	for x in range(-ix, ix + 1):
		for y in range(-iy, iy + 1):
			var d := Vector2(x / rx, y / ry).length()
			if d > 1.0:
				continue
			var alpha := clampf((1.0 - d) / 0.22, 0.0, 1.0)
			var px := int(center.x) + x
			var py := int(center.y) + y
			if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
				continue
			var existing := img.get_pixel(px, py)
			var blend := Color(color.r, color.g, color.b, color.a * alpha)
			if existing.a > 0.01:
				blend = existing.lerp(Color(color.r, color.g, color.b, 1.0), alpha)
			img.set_pixel(px, py, blend)

static func _disc(img: Image, center: Vector2, radius: float, color: Color) -> void:
	var r := int(ceil(radius))
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			if Vector2(x, y).length() <= radius:
				var px := int(center.x) + x
				var py := int(center.y) + y
				if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
					img.set_pixel(px, py, color)

static func _line(img: Image, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var steps := int(maxf(1.0, from.distance_to(to)))
	for i in range(steps + 1):
		var p := from.lerp(to, float(i) / float(steps))
		_disc(img, p, width * 0.5, color)

static func _head_info(model: Node3D, box: AABB) -> Dictionary:
	var threshold := box.position.y + box.size.y * 0.72
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var sum_y := 0.0
	var count := 0
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if str(mi.name).begins_with("Face_") or mi.mesh == null:
			continue
		var xf: Transform3D = model.global_transform.affine_inverse() * mi.global_transform
		for surface in range(mi.mesh.get_surface_count()):
			var arrays: Array = mi.mesh.surface_get_arrays(surface)
			if arrays.size() <= Mesh.ARRAY_VERTEX:
				continue
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for i in range(verts.size()):
				var v: Vector3 = xf * verts[i]
				if v.y >= threshold:
					min_x = minf(min_x, v.x)
					max_x = maxf(max_x, v.x)
					min_z = minf(min_z, v.z)
					sum_y += v.y
					count += 1
	if count == 0:
		return {"center": Vector3(box.position.x + box.size.x * 0.5, box.position.y + box.size.y * 0.86, box.position.z), "width": box.size.x * 0.5}
	return {"center": Vector3((min_x + max_x) * 0.5, sum_y / float(count), min_z), "width": max_x - min_x}

static func _bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if str(mi.name).begins_with("Face_"):
			continue
		var xf: Transform3D = model.global_transform.affine_inverse() * mi.global_transform
		var a: AABB = xf * mi.get_aabb()
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	return box
