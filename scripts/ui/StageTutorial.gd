extends CanvasLayer

# Tutorial interativo da Fase 1: cada objetivo exige uma ação real antes de liberar o próximo.

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

func setup(stage_node: Node3D, king_node: Node3D, merchant_node: Node3D, waves: Node, purchase_pads: Array) -> void:
	stage = stage_node
	king = king_node
	merchant = merchant_node
	wave_manager = waves
	pads = purchase_pads
	start_position = king.global_position
	_build_ui()
	_build_world_arrow()
	_set_pad_locks(true)
	if wave_manager:
		wave_manager.tutorial_hold = true
	is_active = true
	_set_step(0)

func _ready() -> void:
	layer = 30

func _exit_tree() -> void:
	if arrow and is_instance_valid(arrow):
		arrow.queue_free()

func _process(_delta: float) -> void:
	if not is_active or not is_instance_valid(king):
		return
	_update_arrow()
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
	arrow.font_size = 72
	arrow.outline_size = 14
	arrow.outline_modulate = Color("#2B1B12")
	arrow.modulate = Color("#FFC93C")
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.no_depth_test = true
	arrow.fixed_size = true
	arrow.pixel_size = 0.0012
	arrow.render_priority = 20
	stage.add_child(arrow)

func _set_step(next_step: int) -> void:
	step = next_step
	match step:
		0:
			step_label.text = "TUTORIAL 1/5"
			objective_label.text = "Mova o Rei pelo acampamento"
			hint_label.text = "Arraste o joystick. Primeiro aprenda a conduzir Teodoro."
		1:
			_set_pad_locks(false, pads[0] if not pads.is_empty() else null)
			step_label.text = "TUTORIAL 2/5"
			objective_label.text = "Contrate o primeiro arqueiro"
			hint_label.text = "Fique sobre o pad 🏹. Ele está liberado para iniciar a defesa."
		2:
			_set_pad_locks(true)
			if wave_manager:
				wave_manager.tutorial_hold = false
			step_label.text = "TUTORIAL 3/5"
			objective_label.text = "Derrote um monstro e recolha o primeiro capacete"
			hint_label.text = "O capacete aparece depois do puf. Passe com o Rei sobre ele."
		3:
			coins_before_sale = GameState.stage_coins
			step_label.text = "TUTORIAL 4/5"
			objective_label.text = "Leve os capacetes ao balcão do Tobias"
			hint_label.text = "Entre no balcão dourado para trocar 🪖 por moedas."
		4:
			_set_pad_locks(false, pads[2] if pads.size() > 2 else null)
			step_label.text = "TUTORIAL 5/5"
			objective_label.text = "Invista no pad da paliçada"
			hint_label.text = "Fique sobre o pad 🪵 para reforçar o acampamento."

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
		arrow.global_position = target.global_position + Vector3(0, 2.3 + bob, 0)

func _finish_tutorial() -> void:
	if not is_active:
		return
	is_active = false
	_set_pad_locks(false)
	if wave_manager:
		wave_manager.tutorial_hold = false
	SaveManager.save_data["stage_1_tutorial_completed"] = true
	SaveManager.save_game()
	step_label.text = "TUTORIAL CONCLUÍDO"
	objective_label.text = "Agora defenda o acampamento!"
	hint_label.text = "Todos os pads estão liberados. Priorize sua defesa."
	if arrow:
		arrow.visible = false
	get_tree().create_timer(2.0).timeout.connect(queue_free)
