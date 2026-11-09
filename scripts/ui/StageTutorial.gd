extends CanvasLayer

# Tutorial interativo da Fase 1: cada objetivo exige uma ação real antes de liberar o próximo.

const UI_FONT = preload("res://assets/fonts/Fredoka-Variable.ttf")

var stage: Node3D
var king: Node3D
var merchant: Node3D
var wave_manager: Node
var pads: Array = []
var arrow: Label3D
var panel: PanelContainer
var step_label: Label
var objective_label: Label
var hint_label: Label
var step: int = 0
var start_position: Vector3
var coins_before_sale: int = 15
var is_active: bool = false
var highlight_root: Node3D = null
var highlight_ring: MeshInstance3D = null
var highlight_beam: MeshInstance3D = null
var highlight_mat: StandardMaterial3D = null
var beam_mat: StandardMaterial3D = null
var pulse_time: float = 0.0
var wiggle_time: float = 0.0

func setup(stage_node: Node3D, king_node: Node3D, merchant_node: Node3D, waves: Node, purchase_pads: Array) -> void:
	stage = stage_node
	king = king_node
	merchant = merchant_node
	wave_manager = waves
	pads = purchase_pads
	start_position = king.global_position
	_build_ui()
	_build_world_arrow()
	_build_highlight()
	_set_hud_locked(true)
	_set_pad_locks(true)
	if wave_manager:
		wave_manager.tutorial_hold = true
	is_active = true
	GameState.set_dialogue_open(true)
	_set_step(0)

func _ready() -> void:
	layer = 30

func _exit_tree() -> void:
	GameState.set_dialogue_open(false)
	if arrow and is_instance_valid(arrow):
		arrow.queue_free()
	_set_hud_locked(false)

func _process(delta: float) -> void:
	if not is_active or not is_instance_valid(king):
		return
	_update_arrow()
	_update_highlight(delta)
	match step:
		0:
			if king.global_position.distance_to(start_position) >= 1.0:
				_set_step(1)
		1:
			if GameState.active_troops.size() > 0:
				_set_step(2)
		2:
			if GameState.stage_spoils > 0:
				_set_step(3)
		3:
			if GameState.stage_spoils == 0 and GameState.stage_coins > coins_before_sale:
				_set_step(4)
		4:
			if get_tree().get_nodes_in_group("palisades").size() > 0:
				_finish_tutorial()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -300.0
	panel.offset_top = -155.0
	panel.offset_right = 300.0
	panel.offset_bottom = -28.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	step_label = Label.new()
	step_label.add_theme_color_override("font_color", Color("#FFC93C"))
	step_label.add_theme_font_size_override("font_size", 18)
	content.add_child(step_label)
	objective_label = Label.new()
	objective_label.add_theme_color_override("font_color", Color("#FFF3D6"))
	objective_label.add_theme_color_override("font_outline_color", Color("#2B1B12"))
	objective_label.add_theme_constant_override("outline_size", 4)
	objective_label.add_theme_font_size_override("font_size", 23)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(objective_label)
	hint_label = Label.new()
	hint_label.add_theme_color_override("font_color", Color("#D9E8FF"))
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint_label)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.169, 0.106, 0.071, 0.94)
	style.border_color = Color("#FFC93C")
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

func _build_world_arrow() -> void:
	arrow = Label3D.new()
	arrow.text = "▼"
	arrow.font = UI_FONT
	arrow.font_size = 46
	arrow.outline_size = 9
	arrow.outline_modulate = Color("#2B1B12")
	arrow.modulate = Color("#FFC93C")
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.no_depth_test = true
	arrow.fixed_size = true
	arrow.pixel_size = 0.0007
	arrow.render_priority = 20
	stage.add_child(arrow)

func _build_highlight() -> void:
	highlight_root = Node3D.new()
	highlight_root.name = "TutorialHighlight"
	stage.add_child(highlight_root)
	highlight_mat = StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(1.0, 0.78, 0.15, 1.0)
	highlight_mat.emission_enabled = true
	highlight_mat.emission = Color(1.0, 0.75, 0.2)
	highlight_mat.emission_energy_multiplier = 2.4
	highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.2
	highlight_ring.mesh = torus
	highlight_ring.material_override = highlight_mat
	highlight_ring.position.y = 0.09
	highlight_root.add_child(highlight_ring)
	beam_mat = StandardMaterial3D.new()
	beam_mat.albedo_color = Color(1.0, 0.84, 0.35, 0.20)
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(1.0, 0.8, 0.3)
	beam_mat.emission_energy_multiplier = 0.9
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	highlight_beam = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.85
	cylinder.bottom_radius = 0.95
	cylinder.height = 5.0
	highlight_beam.mesh = cylinder
	highlight_beam.material_override = beam_mat
	highlight_beam.position.y = 2.5
	highlight_root.add_child(highlight_beam)

func _highlight_target() -> Node3D:
	match step:
		0:
			return king
		1:
			return pads[0] if not pads.is_empty() else king
		2:
			var spoils := get_tree().get_nodes_in_group("spoils")
			return spoils[0] if not spoils.is_empty() else null
		3:
			return merchant
		4:
			return pads[2] if pads.size() > 2 else king
	return king

func _update_highlight(delta: float) -> void:
	if highlight_root == null:
		return
	var target := _highlight_target()
	if target == null or not is_instance_valid(target):
		highlight_root.visible = false
		return
	highlight_root.visible = true
	var wiggle := Vector3.ZERO
	if wiggle_time > 0.0:
		wiggle = Vector3(sin(wiggle_time * 55.0) * 0.28, 0, 0)
	highlight_root.global_position = target.global_position + Vector3(0, 0.03, 0) + wiggle
	pulse_time += delta
	var pulse := 1.0 + sin(pulse_time * 4.5) * 0.14
	highlight_ring.scale = Vector3(pulse, 1.0, pulse)
	highlight_mat.emission_energy_multiplier = 2.0 + sin(pulse_time * 6.0) * 0.7
	beam_mat.albedo_color.a = 0.16 + 0.07 * (sin(pulse_time * 3.0) * 0.5 + 0.5)
	wiggle_time = maxf(0.0, wiggle_time - delta)

func _set_hud_locked(locked: bool) -> void:
	var hud := stage.get_node_or_null("GameHUD")
	if hud and hud.has_method("set_tutorial_lock"):
		hud.call("set_tutorial_lock", locked)

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventScreenTouch and event.pressed:
		if step == 0:
			return
		var size := get_viewport().get_visible_rect().size
		if event.position.x < size.x * 0.42 and event.position.y > size.y * 0.55:
			return
		var target := _highlight_target()
		var cam := get_viewport().get_camera_3d()
		if target and is_instance_valid(target) and cam:
			var screen_pos := cam.unproject_position(target.global_position)
			if screen_pos.distance_to(event.position) < 150.0:
				return
		wiggle_time = 0.7

func _set_step(next_step: int) -> void:
	step = next_step
	match step:
		0:
			step_label.text = "TUTORIAL 1/5"
			objective_label.text = "Mova o Rei"
			hint_label.text = "Arraste o joystick"
		1:
			_set_pad_locks(false, pads[0] if not pads.is_empty() else null)
			step_label.text = "TUTORIAL 2/5"
			objective_label.text = "Toque no pad ARQUEIRO"
			hint_label.text = "Fique em cima do pad"
		2:
			_set_pad_locks(true)
			if wave_manager:
				wave_manager.tutorial_hold = false
			step_label.text = "TUTORIAL 3/5"
			objective_label.text = "Pegue o capacete"
			hint_label.text = "Passe por cima dele"
		3:
			coins_before_sale = GameState.stage_coins
			step_label.text = "TUTORIAL 4/5"
			objective_label.text = "Venda ao Tobias"
			hint_label.text = "Entre no balcão dourado"
		4:
			_set_pad_locks(false, pads[2] if pads.size() > 2 else null)
			step_label.text = "TUTORIAL 5/5"
			objective_label.text = "Compre a paliçada"
			hint_label.text = "Fique no pad PALIÇADA"

	if merchant and is_instance_valid(merchant) and merchant.has_method("set_tutorial_locked"):
		merchant.call("set_tutorial_locked", step != 3)
	for lbl in [step_label, objective_label, hint_label]:
		I18n.set_text(lbl, lbl.text)
	_update_highlight(0.0)

func _set_pad_locks(locked: bool, only_pad: Node = null) -> void:
	for pad in pads:
		if is_instance_valid(pad) and pad.has_method("set_tutorial_locked"):
			var pad_locked: bool = locked or (only_pad != null and pad != only_pad)
			pad.set_tutorial_locked(pad_locked)

func _update_arrow() -> void:
	if not arrow:
		return
	var target: Node3D = king
	match step:
		3:
			target = merchant
		4:
			target = pads[2] if pads.size() > 2 else king
		1:
			target = pads[0] if not pads.is_empty() else king
		2:
			var spoils := get_tree().get_nodes_in_group("spoils")
			if not spoils.is_empty() and is_instance_valid(spoils[0]):
				target = spoils[0]
	if target and is_instance_valid(target):
		var bob := sin(Time.get_ticks_msec() * 0.006) * 0.18
		arrow.global_position = target.global_position + Vector3(0, 3.0 + bob, 0)

func _finish_tutorial() -> void:
	if not is_active:
		return
	is_active = false
	GameState.set_dialogue_open(false)
	_set_pad_locks(false)
	_set_hud_locked(false)
	if merchant and is_instance_valid(merchant) and merchant.has_method("set_tutorial_locked"):
		merchant.call("set_tutorial_locked", false)
	if highlight_root and is_instance_valid(highlight_root):
		highlight_root.queue_free()
		highlight_root = null
	if wave_manager:
		wave_manager.tutorial_hold = false
	SaveManager.save_data["stage_1_tutorial_completed"] = true
	SaveManager.save_game()
	I18n.set_text(step_label, "TUTORIAL CONCLUÍDO")
	I18n.set_text(objective_label, "Defenda o acampamento!")
	I18n.set_text(hint_label, "Use os pads e vença!")
	if arrow:
		arrow.visible = false
	get_tree().create_timer(2.0).timeout.connect(queue_free)
