extends RefCounted

# ChibiFace.gd - Rosto billboard (sempre de frente para a câmera) estilo brinquedo.
# Funciona em qualquer modelo CC0 sem depender da orientação da malha.

static var _cache: Dictionary = {}

static func attach(model: Node3D, angry: bool = false) -> void:
	if model == null or not model.is_inside_tree():
		return
	if model.get_node_or_null("Face_Root") != null:
		return
	var box := _bounds(model)
	if box.size.y < 0.05:
		return
	var h := box.size.y
	var head := _head_center(model, box)
	var root := Node3D.new()
	root.name = "Face_Root"
	root.position = head
	model.add_child(root)
	var quad := QuadMesh.new()
	quad.size = Vector2(h * 0.36, h * 0.36)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _face_texture(angry)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.25
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var face := MeshInstance3D.new()
	face.name = "Face_Quad"
	face.mesh = quad
	face.material_override = mat
	face.rotation.y = PI
	root.add_child(face)

static func _face_texture(angry: bool) -> ImageTexture:
	var key := "angry" if angry else "happy"
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var white := Color(1, 1, 1, 1)
	var dark := Color(0.10, 0.07, 0.06, 1)
	var pink := Color(0.96, 0.58, 0.58, 0.85)
	for eye in [Vector2(22, 28), Vector2(42, 28)]:
		_disc(img, eye, 9.0, white)
		_disc(img, eye + Vector2(0, 1), 4.6, dark)
		_disc(img, eye + Vector2(-2.5, -2.5), 1.6, white)
	_disc(img, Vector2(12, 40), 3.2, pink)
	_disc(img, Vector2(52, 40), 3.2, pink)
	# sobrancelhas
	_line(img, Vector2(13, 16), Vector2(28, 14 if angry else 12), dark, 3.0)
	_line(img, Vector2(51, 16), Vector2(36, 14 if angry else 12), dark, 3.0)
	# boca
	if angry:
		_line(img, Vector2(24, 44), Vector2(40, 44), dark, 2.6)
	else:
		for x in range(24, 41):
			var t := (x - 32) / 16.0
			var y := 42 + int((1.0 - t * t) * 4.0)
			_disc(img, Vector2(x, y), 1.7, dark)
	return ImageTexture.create_from_image(img)

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

static func _head_center(model: Node3D, box: AABB) -> Vector3:
	var threshold := box.position.y + box.size.y * 0.72
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
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
					max_z = maxf(max_z, v.z)
					sum_y += v.y
					count += 1
	if count == 0:
		return Vector3(box.position.x + box.size.x * 0.5, box.position.y + box.size.y * 0.86, box.position.z - box.size.y * 0.008)
	var center_x := (min_x + max_x) * 0.5
	var center_z := (min_z + max_z) * 0.5
	return Vector3(center_x, sum_y / float(count), min_z - box.size.y * 0.006)

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
