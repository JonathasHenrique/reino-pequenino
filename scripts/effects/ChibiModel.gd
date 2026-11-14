extends RefCounted

# ChibiModel.gd - Instancia personagens KayKit (CC0) com rosto, capuz/chapéu e braços em pose natural.

const MODELS := {
	"knight": "Knight",
	"barbarian": "Barbarian",
	"mage": "Mage",
	"rogue": "Rogue",
	"rogue_hooded": "Rogue_Hooded",
}

static var _scene_cache: Dictionary = {}

static func spawn(parent: Node3D, model_key: String, target_height: float = 3.05, tint: Color = Color.WHITE, rotate_pi: bool = false, cast_shadows: bool = false) -> Node3D:
	var model_name: String = MODELS.get(model_key, "Knight")
	var path := "res://assets/models/chibi/%s.glb" % model_name
	var packed: PackedScene = _scene_cache.get(path)
	if packed == null:
		packed = load(path) as PackedScene
		if packed != null:
			_scene_cache[path] = packed
	if packed == null:
		return null
	var inst := packed.instantiate() as Node3D
	parent.add_child(inst)

	for sk in inst.find_children("*", "Skeleton3D", true, false):
		var skeleton := sk as Skeleton3D
		for b in range(skeleton.get_bone_count()):
			var bone := skeleton.get_bone_name(b)
			if bone == "upperarm.l":
				skeleton.set_bone_pose_rotation(b, Quaternion(Vector3(0, 1, 0), 1.15))
			elif bone == "upperarm.r":
				skeleton.set_bone_pose_rotation(b, Quaternion(Vector3(0, 1, 0), -1.15))
			elif bone == "lowerarm.l":
				skeleton.set_bone_pose_rotation(b, Quaternion(Vector3(0, 0, 1), -0.15))
			elif bone == "lowerarm.r":
				skeleton.set_bone_pose_rotation(b, Quaternion(Vector3(0, 0, 1), 0.15))

	_hide_weapons(inst)
	var box := _bounds(inst, true)
	if box.size.y < 0.05:
		box = AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 2.5, 1.0))
	var factor := target_height / box.size.y
	inst.scale = Vector3.ONE * factor
	var ground := _foot_y(inst)
	if ground == INF:
		ground = box.position.y
	inst.position.y = -ground * factor
	if rotate_pi:
		inst.rotation.y = PI
	if tint != Color.WHITE:
		_tint(inst, tint)
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst

static func _hide_weapons(root: Node3D) -> void:
	var keywords := ["Sword", "Axe", "Shield", "Mug", "Crossbow", "Knife", "Throwable", "Staff", "Wand", "Spellbook", "Arrow", "Bow", "Torch", "Wrench"]
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var node: Node = m
		var hide := false
		while node != null and node != root:
			var n := str(node.name)
			for k in keywords:
				if n.contains(k):
					hide = true
					break
			if hide:
				break
			node = node.get_parent()
		if hide:
			(m as MeshInstance3D).visible = false

static func _foot_y(root: Node3D) -> float:
	var ground := INF
	for sk in root.find_children("*", "Skeleton3D", true, false):
		var skeleton := sk as Skeleton3D
		for b in range(skeleton.get_bone_count()):
			var bone := skeleton.get_bone_name(b)
			if bone == "toes.l" or bone == "toes.r" or bone == "foot.l" or bone == "foot.r":
				ground = minf(ground, skeleton.get_bone_global_pose(b).origin.y)
	return ground

static func _bounds(root: Node3D, body_only: bool = false) -> AABB:
	var box := AABB()
	var first := true
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if body_only and mi.skin == null:
			continue
		var xf: Transform3D = root.global_transform.affine_inverse() * mi.global_transform
		var a: AABB = xf * mi.get_aabb()
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	return box

static func _tint(root: Node3D, tint: Color) -> void:
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var mat := mi.get_active_material(s)
			if mat is BaseMaterial3D:
				var dup := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				dup.albedo_color = tint
				mi.material_override = dup
				break
