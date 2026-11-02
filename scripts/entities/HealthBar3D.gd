extends MeshInstance3D

# HealthBar3D.gd - Barrinha de vida flutuante (inimigos, muros, torres, tenda).
# Fica escondida com vida cheia para não poluir a tela; aparece ao sofrer dano.

const SHADER: Shader = preload("res://assets/shaders/healthbar.gdshader")
var always_visible: bool = false

static func create(parent: Node3D, height: float, width: float = 1.3, color: Color = Color(0.35, 0.85, 0.30), show_always: bool = false) -> MeshInstance3D:
	var script = load("res://scripts/entities/HealthBar3D.gd") as GDScript
	var bar = script.new() as MeshInstance3D
	var q = QuadMesh.new()
	q.size = Vector2(width, width * 0.16)
	bar.mesh = q
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.render_priority = 3
	material.set_shader_parameter("fill_color", color)
	bar.material_override = material
	bar.position = Vector3(0, height, 0)
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.always_visible = show_always
	parent.add_child(bar)
	bar.set_ratio(1.0)
	return bar

func set_ratio(r: float) -> void:
	r = clampf(r, 0.0, 1.0)
	var material := material_override as ShaderMaterial
	if material:
		material.set_shader_parameter("ratio", r)
	visible = always_visible or r < 0.999
	# Cor muda de verde para amarelo e vermelho conforme a vida cai
	if not always_visible:
		var c = Color(0.35, 0.85, 0.30)
		if r < 0.3:
			c = Color(0.95, 0.30, 0.22)
		elif r < 0.6:
			c = Color(0.98, 0.78, 0.22)
		if material:
			material.set_shader_parameter("fill_color", c)
