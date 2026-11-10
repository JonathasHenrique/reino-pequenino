extends CanvasLayer

# StageTutorial.gd - Tutorial linear guiado da Fase 1 com Feixe de Lanterna 3D,
# bloqueio progressivo de pads, controle de tempo e destaque no Totem da Bruma.

const UI_FONT = preload("res://assets/fonts/Fredoka-Variable.ttf")

var stage: Node3D
var king: Node3D
var merchant: Node3D
var totem: Node3D
var camera: Camera3D
var wave_manager: Node
var pads: Array = []
var arrow: Label3D
var target_banner_3d: Label3D
var panel: PanelContainer
var step_label: Label
var objective_label: Label
var hint_label: Label
var step: int = 1
var coins_before_sale: int = 15
var is_active: bool = false
var highlight_root: Node3D = null
var highlight_ring: MeshInstance3D = null
var highlight_outer_ring: MeshInstance3D = null
var highlight_beam: MeshInstance3D = null
var highlight_cone: MeshInstance3D = null
var highlight_mat: StandardMaterial3D = null
var beam_mat: StandardMaterial3D = null
var pulse_time: float = 0.0
var wiggle_time: float = 0.0
var step5_timer: float = 0.0
var step6_timer: float = 0.0
var _slowmo_tween: Tween = null
var _enemy_spotted_slowmo: bool = false
var _spoil_spotted_slowmo: bool = false

func setup(stage_node: Node3D, king_node: Node3D, merchant_node: Node3D, waves: Node, purchase_pads: Array) -> void:
	stage = stage_node
	king = king_node
	merchant = merchant_node
	wave_manager = waves
	pads = purchase_pads
	totem = stage.get_node_or_null("MistTotem") as Node3D
	camera = stage.get_node_or_null("IsometricCamera") as Camera3D
	_build_ui()
	_build_world_arrow()
	_build_highlight()
	_set_hud_locked(true)
	_set_pad_locks(true)
	if wave_manager:
		wave_manager.tutorial_hold = true
	is_active = true
	GameState.set_dialogue_open(true)
	GameState.hero_ability_used.connect(_on_hero_ability_used)
	_set_step(1)

func _ready() -> void:
	layer = 30

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	GameState.set_dialogue_open(false)
	if arrow and is_instance_valid(arrow):
		arrow.queue_free()
	if target_banner_3d and is_instance_valid(target_banner_3d):
		target_banner_3d.queue_free()
	_set_hud_locked(false)

func _trigger_educational_slowmo(min_scale: float = 0.42, duration: float = 0.85) -> void:
	if _slowmo_tween and _slowmo_tween.is_valid():
		_slowmo_tween.kill()
	Engine.time_scale = min_scale
	_slowmo_tween = create_tween()
	_slowmo_tween.tween_property(Engine, "time_scale", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_hero_ability_used(_hero_id: String) -> void:
	if is_active and step == 5:
		_set_step(6)

func _process(delta: float) -> void:
	if not is_active or not is_instance_valid(king):
		return
	_update_arrow()
	_update_highlight(delta)
	match step:
		1:
			# Passo 1: comprar o 1º Arqueiro no Pad Azul
			if GameState.active_troops.size() > 0:
				_set_step(2)
		2:
			# Passo 2: derrotar inimigo e recolher o capacete (SpoilLoot)
			var spoils := get_tree().get_nodes_in_group("spoils")
			if not spoils.is_empty() and not _spoil_spotted_slowmo:
				_spoil_spotted_slowmo = true
				if wave_manager:
					wave_manager.tutorial_hold = true
				_trigger_educational_slowmo(0.40, 0.90)
			if GameState.stage_spoils > 0:
				_set_step(3)
		3:
			# Passo 3: vender capacetes no balcão do Mercador Tobias
			if GameState.stage_spoils == 0 and GameState.stage_coins > coins_before_sale:
				_set_step(4)
		4:
			# Passo 4: construir a 1ª Paliçada no Pad Verde
			if get_tree().get_nodes_in_group("palisades").size() > 0:
				_set_step(5)
		5:
			# Passo 5: conhecer Torre (Laranja), Forja (Vermelho), Quartel (Roxo) e Grito de Coragem
			step5_timer += delta
			var towers_arr: Array = stage.get("active_towers") if stage.get("active_towers") is Array else []
			var built_extra: bool = (towers_arr.size() > 0) or bool(stage.get("forge_built")) or bool(stage.get("barracks_built"))
			if built_extra or step5_timer >= 5.5:
				_set_step(6)
		6:
			# Passo 6: foco no Totem da Bruma até concluir o tutorial ou destruir o Totem
			step6_timer += delta
			if step6_timer >= 6.5:
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
	panel.offset_left = -380.0
	panel.offset_top = -178.0
	panel.offset_right = 380.0
	panel.offset_bottom = -24.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)

	# Retrato da Dona Zenaide no tutorial
	var portrait_rect := TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(76, 76)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/ui/portraits/zenaide.png"):
		portrait_rect.texture = load("res://assets/ui/portraits/zenaide.png") as Texture2D
	hbox.add_child(portrait_rect)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(content)

	step_label = Label.new()
	step_label.add_theme_color_override("font_color", Color("#FFC93C"))
	step_label.add_theme_font_size_override("font_size", 18)
	content.add_child(step_label)
	objective_label = Label.new()
	objective_label.add_theme_color_override("font_color", Color("#FFF3D6"))
	objective_label.add_theme_color_override("font_outline_color", Color("#2B1B12"))
	objective_label.add_theme_constant_override("outline_size", 4)
	objective_label.add_theme_font_size_override("font_size", 21)
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
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

func _build_world_arrow() -> void:
	arrow = Label3D.new()
	arrow.text = "▼"
	arrow.font = UI_FONT
	arrow.font_size = 52
	arrow.outline_size = 11
	arrow.outline_modulate = Color("#2B1B12")
	arrow.modulate = Color("#FFC93C")
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.no_depth_test = true
	arrow.fixed_size = true
	arrow.pixel_size = 0.00075
	arrow.render_priority = 20
	stage.add_child(arrow)

	target_banner_3d = Label3D.new()
	target_banner_3d.text = "🎯 ALVO PRINCIPAL"
	target_banner_3d.font = UI_FONT
	target_banner_3d.font_size = 36
	target_banner_3d.outline_size = 12
	target_banner_3d.outline_modulate = Color(0.12, 0.03, 0.03, 1.0)
	target_banner_3d.modulate = Color(1.0, 0.88, 0.25, 1.0)
	target_banner_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	target_banner_3d.no_depth_test = true
	target_banner_3d.fixed_size = true
	target_banner_3d.pixel_size = 0.00068
	target_banner_3d.render_priority = 22
	target_banner_3d.visible = false
	I18n.protect(target_banner_3d)
	stage.add_child(target_banner_3d)

func _build_highlight() -> void:
	highlight_root = Node3D.new()
	highlight_root.name = "TutorialHighlight"
	stage.add_child(highlight_root)
	highlight_mat = StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(1.0, 0.82, 0.18, 0.95)
	highlight_mat.emission_enabled = true
	highlight_mat.emission = Color(1.0, 0.78, 0.20)
	highlight_mat.emission_energy_multiplier = 2.6
	highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.15
	torus.outer_radius = 1.48
	highlight_ring.mesh = torus
	highlight_ring.material_override = highlight_mat
	highlight_ring.position.y = 0.10
	highlight_root.add_child(highlight_ring)

	highlight_outer_ring = MeshInstance3D.new()
	var outer_torus := TorusMesh.new()
	outer_torus.inner_radius = 1.65
	outer_torus.outer_radius = 1.82
	highlight_outer_ring.mesh = outer_torus
	highlight_outer_ring.material_override = highlight_mat
	highlight_outer_ring.position.y = 0.08
	highlight_root.add_child(highlight_outer_ring)

	beam_mat = StandardMaterial3D.new()
	beam_mat.albedo_color = Color(1.0, 0.88, 0.32, 0.30)
	beam_mat.emission_enabled = true
	beam_mat.emission = Color(1.0, 0.84, 0.28)
	beam_mat.emission_energy_multiplier = 1.45
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	highlight_beam = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.55
	cylinder.bottom_radius = 1.45
	cylinder.height = 8.5
	highlight_beam.mesh = cylinder
	highlight_beam.material_override = beam_mat
	highlight_beam.position.y = 4.25
	highlight_root.add_child(highlight_beam)

func _highlight_target() -> Node3D:
	match step:
		1:
			return pads[0] if not pads.is_empty() else king
		2:
			var spoils := get_tree().get_nodes_in_group("spoils")
			if not spoils.is_empty() and is_instance_valid(spoils[0]):
				return spoils[0]
			var enemies := get_tree().get_nodes_in_group("enemies")
			if not enemies.is_empty() and is_instance_valid(enemies[0]):
				return enemies[0]
			return king
		3:
			return merchant
		4:
			return pads[2] if pads.size() > 2 else king
		5:
			var cycle_pads: Array[Node3D] = []
			if pads.size() > 1 and is_instance_valid(pads[1]):
				cycle_pads.append(pads[1]) # Torre (Laranja)
			if pads.size() > 4 and is_instance_valid(pads[4]):
				cycle_pads.append(pads[4]) # Forja (Vermelho)
			if pads.size() > 3 and is_instance_valid(pads[3]):
				cycle_pads.append(pads[3]) # Quartel (Roxo)
			if not cycle_pads.is_empty():
				var idx := int(step5_timer / 1.6) % cycle_pads.size()
				return cycle_pads[idx]
			return king
		6:
			if totem and is_instance_valid(totem):
				return totem
			return king
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
	highlight_root.global_position = target.global_position + Vector3(0, 0.04, 0) + wiggle
	pulse_time += delta
	var pulse := 1.0 + sin(pulse_time * 4.8) * 0.15
	highlight_ring.scale = Vector3(pulse, 1.0, pulse)
	if highlight_outer_ring:
		var outer_pulse := 1.0 + cos(pulse_time * 4.8) * 0.12
		highlight_outer_ring.scale = Vector3(outer_pulse, 1.0, outer_pulse)
	if step == 6:
		# Cor vermelha/dourada pulsante de Alvo Principal na Torre/Totem Inimigo
		var target_mix := sin(pulse_time * 6.0) * 0.5 + 0.5
		var col := Color(1.0, 0.22, 0.16).lerp(Color(1.0, 0.82, 0.18), target_mix)
		highlight_mat.albedo_color = Color(col.r, col.g, col.b, 0.98)
		highlight_mat.emission = col
		highlight_mat.emission_energy_multiplier = 2.8 + target_mix * 0.9
		beam_mat.albedo_color = Color(1.0, 0.35, 0.18, 0.32 + 0.10 * target_mix)
		beam_mat.emission = Color(1.0, 0.45, 0.18)
	else:
		# Lanterna amarela/dourada brilhante nos pads, capacete e mercador
		highlight_mat.albedo_color = Color(1.0, 0.84, 0.18, 0.96)
		highlight_mat.emission = Color(1.0, 0.80, 0.20)
		highlight_mat.emission_energy_multiplier = 2.2 + sin(pulse_time * 6.0) * 0.7
		beam_mat.albedo_color = Color(1.0, 0.88, 0.32, 0.26 + 0.09 * (sin(pulse_time * 3.5) * 0.5 + 0.5))
		beam_mat.emission = Color(1.0, 0.84, 0.28)
	wiggle_time = maxf(0.0, wiggle_time - delta)

func _set_hud_locked(locked: bool) -> void:
	var hud := stage.get_node_or_null("GameHUD")
	if hud and hud.has_method("set_tutorial_lock"):
		hud.call("set_tutorial_lock", locked)

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventScreenTouch and event.pressed:
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
	var lang := I18n.language
	if target_banner_3d:
		target_banner_3d.visible = (step == 6)
		if lang == "en":
			target_banner_3d.text = "🎯 MAIN TARGET\nMIST TOTEM"
		elif lang == "es":
			target_banner_3d.text = "🎯 OBJETIVO PRINCIPAL\nTÓTEM DE LA BRUMA"
		else:
			target_banner_3d.text = "🎯 ALVO PRINCIPAL\nTOTEM DA BRUMA"

	match step:
		1:
			# Passo 1: apenas Pad Azul (recruit_archer) desbloqueado; spawn de inimigos pausado
			_set_pad_locks(false, pads[0] if not pads.is_empty() else null)
			if wave_manager:
				wave_manager.tutorial_hold = true
			if lang == "en":
				step_label.text = "STEP 1/6 — RECRUIT ARCHER"
				objective_label.text = "Grandma Zenaide: Step onto the BLUE PAD (🏹 Archer) to recruit your 1st ally!"
				hint_label.text = "Follow the yellow spotlight beam to the Blue Pad."
			elif lang == "es":
				step_label.text = "PASO 1/6 — RECLUTAR ARQUERO"
				objective_label.text = "Abuela Zenaide: ¡Pisa el PAD AZUL (🏹 Arquero) para reclutar a tu 1er aliado!"
				hint_label.text = "Sigue el haz de luz amarillo hasta el Pad Azul."
			else:
				step_label.text = "PASSO 1/6 — RECRUTAR ARQUEIRO"
				objective_label.text = "Dona Zenaide: Pise no PAD AZUL (🏹 Arqueiro) iluminado pela lanterna para recrutar seu 1º aliado!"
				hint_label.text = "Os demais pads estão bloqueados até você aprender cada função."
		2:
			# Passo 2: libera a 1ª onda; ao cair o capacete, a lanterna aponta para ele
			_set_pad_locks(true)
			if wave_manager:
				wave_manager.tutorial_hold = false
				if wave_manager.get("is_in_prep_phase"):
					wave_manager.set("prep_timer", 0.25)
			_trigger_educational_slowmo(0.55, 0.75)
			if lang == "en":
				step_label.text = "STEP 2/6 — COMBAT & SPOILS"
				objective_label.text = "Grandma Zenaide: Defeat the Mist monster and pick up the HELMET it drops!"
				hint_label.text = "The spotlight beam points directly to the dropped helmet on the ground."
			elif lang == "es":
				step_label.text = "PASO 2/6 — COMBATE Y BOTÍN"
				objective_label.text = "Abuela Zenaide: ¡Derrota al monstruo y recoge el CASCO que suelta en el suelo!"
				hint_label.text = "El haz de luz apunta directamente al casco caído."
			else:
				step_label.text = "PASSO 2/6 — COMBATE E ESPÓLIO"
				objective_label.text = "Dona Zenaide: Derrote o monstro da bruma e passe por cima do CAPACETE que cair no chão!"
				hint_label.text = "O feixe de luz aponta direto para o capacete caído."
		3:
			# Passo 3: vender capacetes no Mercador Tobias; pausa o timer das ondas
			coins_before_sale = GameState.stage_coins
			if wave_manager:
				wave_manager.tutorial_hold = true
			_trigger_educational_slowmo(0.48, 0.80)
			if lang == "en":
				step_label.text = "STEP 3/6 — SELL TO MERCHANT TOBIAS"
				objective_label.text = "Grandma Zenaide: Take the helmets to Merchant Tobias's tent to turn them into GOLD COINS!"
				hint_label.text = "Walk into the golden counter highlighted by the spotlight."
			elif lang == "es":
				step_label.text = "PASO 3/6 — VENDER AL MERCADER TOBIAS"
				objective_label.text = "Abuela Zenaide: ¡Lleva los cascos a la tienda de Tobias para cambiarlos por MONEDAS DE ORO!"
				hint_label.text = "Entra en el mostrador dorado iluminado por la linterna."
			else:
				step_label.text = "PASSO 3/6 — VENDER NO MERCADOR TOBIAS"
				objective_label.text = "Dona Zenaide: Leve os capacetes até a barraca do Mercador Tobias para converter em MOEDAS!"
				hint_label.text = "Entre no balcão dourado iluminado pelo feixe de luz."
		4:
			# Passo 4: desbloqueia o Pad Verde (build_palisade) e garante moedas suficientes
			var palisade_pad_node = pads[2] if pads.size() > 2 else null
			_set_pad_locks(false, palisade_pad_node)
			if palisade_pad_node and is_instance_valid(palisade_pad_node):
				var needed: int = int(palisade_pad_node.get("current_cost")) - GameState.stage_coins
				if needed > 0:
					GameState.add_stage_coins(needed)
			if wave_manager:
				wave_manager.tutorial_hold = true
			_trigger_educational_slowmo(0.48, 0.80)
			if lang == "en":
				step_label.text = "STEP 4/6 — RAISE PALISADE (WALL)"
				objective_label.text = "Grandma Zenaide: Step on the GREEN PAD (🪵 Palisade) to build a wooden wall that blocks enemies!"
				hint_label.text = "Walls protect your camp while archers shoot from behind."
			elif lang == "es":
				step_label.text = "PASO 4/6 — ERGUIR EMPALIZADA (MURO)"
				objective_label.text = "Abuela Zenaide: ¡Pisa el PAD VERDE (🪵 Empalizada) para levantar un muro que frena a los enemigos!"
				hint_label.text = "El muro protege el campamento mientras tus arqueros disparan."
			else:
				step_label.text = "PASSO 4/6 — ERGUER PALIÇADA (MURO)"
				objective_label.text = "Dona Zenaide: Pise no PAD VERDE (🪵 Paliçada) iluminado para erguer o muro que bloqueia os inimigos!"
				hint_label.text = "O muro segura o avanço dos monstros enquanto seus arqueiros atiram."
		5:
			# Passo 5: desbloqueia Torre (Laranja), Forja (Vermelho), Quartel (Roxo) e o botão Grito de Coragem
			step5_timer = 0.0
			_set_pad_locks(false)
			_set_hud_locked(false)
			if wave_manager:
				wave_manager.tutorial_hold = true
			_trigger_educational_slowmo(0.45, 0.90)
			if lang == "en":
				step_label.text = "STEP 5/6 — TOWERS, FORGE & COURAGE CRY"
				objective_label.text = "All Pads Unlocked! ORANGE = Watchtower | RED = Forge (+Damage) | PURPLE = Barracks (+Troops)"
				hint_label.text = "Tap the golden 'COURAGE CRY' button on the bottom-right HUD to buff your army!"
			elif lang == "es":
				step_label.text = "PASO 5/6 — TORRES, FORJA Y GRITO DE CORAJE"
				objective_label.text = "¡Pads Desbloqueados! NARANJA = Torre | ROJO = Forja (+Daño) | MORADO = Cuartel (+Tropas)"
				hint_label.text = "¡Toca el botón 'GRITO DE CORAJE' abajo a la derecha para acelerar tu ejército!"
			else:
				step_label.text = "PASSO 5/6 — TORRE, FORJA E GRITO DE CORAGEM"
				objective_label.text = "Pads Liberados! LARANJA = 🏰 Torre de Alcance | VERMELHO = ⚒️ Forja (+Dano) | ROXO = ⛺ Quartel"
				hint_label.text = "Toque também no botão 'GRITO DE CORAGEM' no canto inferior direito para turbinar suas tropas!"
		6:
			# Passo 6: Objetivo Final — aponta feixe vermelho/dourado para o Totem da Bruma + Pan de Câmera
			step6_timer = 0.0
			_set_pad_locks(false)
			_set_hud_locked(false)
			if wave_manager:
				wave_manager.tutorial_hold = true
			_trigger_educational_slowmo(0.42, 1.15)
			if camera and is_instance_valid(camera) and totem and is_instance_valid(totem) and camera.has_method("pan_to_point"):
				camera.call("pan_to_point", totem.global_position, 1.5)
			if lang == "en":
				step_label.text = "STEP 6/6 — MAIN TARGET: MIST TOTEM"
				objective_label.text = "Grandma Zenaide: \"Now advance with your troops and destroy the Mist Totem to win the battle!\""
				hint_label.text = "Defeat the waves to break the Totem's shield, then tear it down!"
			elif lang == "es":
				step_label.text = "PASO 6/6 — OBJETIVO FINAL: TÓTEM DE LA BRUMA"
				objective_label.text = "Abuela Zenaide: \"¡Ahora avanza con tus tropas y derriba el Tótem de la Bruma para ganar la batalla!\""
				hint_label.text = "¡Vence las oleadas para romper el escudo del Tótem y derríbalo!"
			else:
				step_label.text = "PASSO 6/6 — OBJETIVO FINAL: TOTEM DA BRUMA"
				objective_label.text = "Dona Zenaide: \"Agora avance com suas tropas e derrube o Totem da Bruma para vencer a batalha!\""
				hint_label.text = "Vença as ondas para quebrar o escudo da Torre da Bruma e derrube-a!"
			get_tree().create_timer(2.2).timeout.connect(func():
				if is_instance_valid(self) and wave_manager:
					wave_manager.tutorial_hold = false
			)

	if merchant and is_instance_valid(merchant) and merchant.has_method("set_tutorial_locked"):
		merchant.call("set_tutorial_locked", step < 3)
	for lbl in [step_label, objective_label, hint_label]:
		I18n.protect(lbl)
	_update_highlight(0.0)
	_update_arrow()

func _set_pad_locks(locked: bool, only_pad: Node = null) -> void:
	for pad in pads:
		if is_instance_valid(pad) and pad.has_method("set_tutorial_locked"):
			var pad_locked: bool = locked or (only_pad != null and pad != only_pad)
			pad.set_tutorial_locked(pad_locked)

func _update_arrow() -> void:
	if not arrow:
		return
	var target: Node3D = _highlight_target()
	if target and is_instance_valid(target):
		var bob := sin(Time.get_ticks_msec() * 0.006) * 0.22
		if step == 6:
			arrow.text = "🎯\n▼"
			arrow.modulate = Color(1.0, 0.35, 0.20)
			arrow.global_position = target.global_position + Vector3(0, 4.6 + bob, 0)
			if target_banner_3d:
				target_banner_3d.global_position = target.global_position + Vector3(0, 5.75 + bob, 0)
		else:
			arrow.text = "▼"
			arrow.modulate = Color("#FFC93C")
			arrow.global_position = target.global_position + Vector3(0, 3.2 + bob, 0)

func _finish_tutorial() -> void:
	if not is_active:
		return
	is_active = false
	Engine.time_scale = 1.0
	GameState.set_dialogue_open(false)
	_set_pad_locks(false)
	_set_hud_locked(false)
	if merchant and is_instance_valid(merchant) and merchant.has_method("set_tutorial_locked"):
		merchant.call("set_tutorial_locked", false)
	if wave_manager:
		wave_manager.tutorial_hold = false
	SaveManager.save_data["stage_1_tutorial_completed"] = true
	SaveManager.save_game()
	if arrow and is_instance_valid(arrow):
		arrow.visible = false
	# Mantém o destaque sutil no Totem ou limpa ao encerrar
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(self):
			if highlight_root and is_instance_valid(highlight_root):
				highlight_root.queue_free()
				highlight_root = null
			queue_free()
	)
