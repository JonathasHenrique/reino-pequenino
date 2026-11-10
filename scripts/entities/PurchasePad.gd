extends Area3D

const UI_FONT = preload("res://assets/fonts/Fredoka-Variable.ttf")

# PurchasePad.gd - Plataforma de Compra Ampla e Legível (Estilo Kingshot / Clash of Clans)
# Emblema 3D estilizado, título fixo em tela e custo em moedas de fácil visualização

signal purchase_completed(pad_type: String)

@export var pad_type: String = "recruit_archer"
@export var base_cost: int = 5
@export var cost_increment_per_purchase: int = 1
@export var spend_interval: float = 0.09

var current_cost: int = 5
var current_raw_cost: int = 5
var current_paid: int = 0
var is_king_present: bool = false
var spend_timer: float = 0.0

var is_locked: bool = false
var tutorial_locked: bool = false
var locked_message: String = ""

var current_items: int = 0
var max_items: int = 0
var is_repair_mode: bool = false

@onready var cost_label_3d: Label3D = $Label3D
@onready var status_plate: MeshInstance3D = $StatusPlate
@onready var fill_mesh: MeshInstance3D = $FillProgress
@onready var base_mesh: MeshInstance3D = $BaseMesh
@onready var emblems: Node3D = get_node_or_null("Emblems")
@onready var cost_coin: MeshInstance3D = $CostCoin

var status_material: StandardMaterial3D
var cost_material: StandardMaterial3D
var base_material: StandardMaterial3D
var base_pad_color: Color = Color(0.15, 0.48, 0.85, 0.85)

func get_total_discount() -> float:
	var discount = 0.0
	if SaveManager.save_data.get("selected_hero") == "marta":
		discount += 0.15
	var blacksmith_lvl = int(SaveManager.save_data.get("village_buildings", {}).get("blacksmith", 1))
	if blacksmith_lvl > 1:
		discount += (blacksmith_lvl - 1) * 0.05
	return clampf(discount, 0.0, 0.50)

func _calculate_discounted_cost(raw_cost: int) -> int:
	var discount = get_total_discount()
	if discount > 0.0:
		return maxi(3, int(ceil(float(raw_cost) * (1.0 - discount))))
	return raw_cost

func _ready() -> void:
	current_raw_cost = base_cost
	current_cost = _calculate_discounted_cost(current_raw_cost)
	if cost_label_3d:
		cost_label_3d.font = UI_FONT
		I18n.protect(cost_label_3d)
	_setup_pad_visuals()
	_update_ui()
	# Pequeno afastamento do chão evita z-fighting das bordas com a laje (riscos).
	position.y += 0.05
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.coins_changed.connect(func(_c): _update_ui())
	I18n.language_changed.connect(func(_l): _update_ui())

func _setup_pad_visuals() -> void:
	var col = Color(0.15, 0.48, 0.85, 0.85)
	status_material = StandardMaterial3D.new()
	status_material.albedo_color = Color("#2B1B12")
	status_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	status_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	status_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	status_plate.material_override = status_material

	cost_material = StandardMaterial3D.new()
	cost_material.albedo_color = Color("#FFC93C")
	cost_material.emission_enabled = true
	cost_material.emission = Color("#FFC93C")
	cost_material.emission_energy_multiplier = 0.35
	cost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cost_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	cost_coin.material_override = cost_material
	
	if cost_coin:
		cost_coin.visible = false
	
	if emblems:
		emblems.scale = Vector3.ONE * 1.35
		var bow = emblems.get_node_or_null("BowEmblem")
		var tower = emblems.get_node_or_null("TowerEmblem")
		var palisade = emblems.get_node_or_null("PalisadeEmblem")
		var forge = emblems.get_node_or_null("ForgeEmblem")
		
		if bow: bow.visible = (pad_type == "recruit_archer")
		if tower:
			tower.visible = (pad_type == "build_tower")
			if tower.get_child_count() == 0:
				Art.cyl(tower, 0.36, 0.36, 0.14, Vector3(0, 0.30, 0), Art.STONE)
				Art.cone(tower, 0.42, 0.34, Vector3(0, 0.52, 0), Color(0.88, 0.46, 0.14))
		if palisade:
			palisade.visible = (pad_type == "build_palisade")
			if palisade.get_child_count() == 0:
				Art.cone(palisade, 0.11, 0.22, Vector3(0, 0.36, 0), Art.WOOD_LIGHT)
				Art.cyl(palisade, 0.08, 0.11, 0.50, Vector3(-0.24, -0.02, 0), Art.WOOD)
				Art.cone(palisade, 0.10, 0.20, Vector3(-0.24, 0.32, 0), Art.WOOD_LIGHT)
				Art.cyl(palisade, 0.08, 0.11, 0.50, Vector3(0.24, -0.02, 0), Art.WOOD)
				Art.cone(palisade, 0.10, 0.20, Vector3(0.24, 0.32, 0), Art.WOOD_LIGHT)
				Art.box(palisade, Vector3(0.68, 0.09, 0.14), Vector3(0, 0.05, 0), Art.WOOD_DARK)
		if forge:
			forge.visible = (pad_type == "build_forge")
			if forge.get_child_count() == 0:
				# Bigorna escura + chama laranja/amarela vibrante + espada/martelo dourado claro no topo
				Art.box(forge, Vector3(0.62, 0.16, 0.28), Vector3(0, 0.14, 0), Color(0.22, 0.24, 0.28))
				var flame_outer := Art.cone(forge, 0.24, 0.42, Vector3(0.0, 0.38, -0.05), Color(1.0, 0.48, 0.08))
				var flame_mat := StandardMaterial3D.new()
				flame_mat.albedo_color = Color(1.0, 0.52, 0.10)
				flame_mat.emission_enabled = true
				flame_mat.emission = Color(1.0, 0.45, 0.05)
				flame_mat.emission_energy_multiplier = 1.6
				flame_outer.material_override = flame_mat
				var flame_inner := Art.cone(forge, 0.14, 0.30, Vector3(0.0, 0.42, 0.02), Color(1.0, 0.90, 0.22))
				var inner_mat := StandardMaterial3D.new()
				inner_mat.albedo_color = Color(1.0, 0.92, 0.25)
				inner_mat.emission_enabled = true
				inner_mat.emission = Color(1.0, 0.88, 0.20)
				inner_mat.emission_energy_multiplier = 2.0
				flame_inner.material_override = inner_mat
				# Martelo/Espada dourada clara cruzada sobre a bigorna
				var hammer_pivot := Node3D.new()
				hammer_pivot.position = Vector3(0, 0.32, 0.06)
				hammer_pivot.rotation.z = deg_to_rad(-28.0)
				forge.add_child(hammer_pivot)
				Art.cyl(hammer_pivot, 0.04, 0.04, 0.52, Vector3.ZERO, Art.WOOD_LIGHT)
				var head_mesh := Art.box(hammer_pivot, Vector3(0.30, 0.15, 0.16), Vector3(0, 0.24, 0), Color(1.0, 0.84, 0.22))
				var gold_mat := StandardMaterial3D.new()
				gold_mat.albedo_color = Color(1.0, 0.86, 0.24)
				gold_mat.metallic = 0.45
				gold_mat.roughness = 0.25
				gold_mat.emission_enabled = true
				gold_mat.emission = Color(1.0, 0.78, 0.15)
				gold_mat.emission_energy_multiplier = 0.65
				head_mesh.material_override = gold_mat
		var barracks := emblems.get_node_or_null("BarracksEmblem")
		if barracks == null:
			barracks = Node3D.new()
			barracks.name = "BarracksEmblem"
			barracks.position = Vector3(0, 0.38, 0)
			Art.box(barracks, Vector3(0.55, 0.4, 0.45), Vector3.ZERO, Art.WOOD_LIGHT)
			Art.roof(barracks, Vector3(0.7, 0.32, 0.6), Vector3(0, 0.3, 0), Color(0.58, 0.28, 0.85))
			emblems.add_child(barracks)
		barracks.visible = (pad_type == "build_barracks")

	if pad_type == "recruit_archer" and get_node_or_null("Miniature") == null:
		var mini := load("res://assets/models/characters/QuaterniusRanger.tscn").instantiate() as Node3D
		mini.name = "Miniature"
		mini.scale = Vector3.ONE * 0.58
		mini.position = Vector3(0, 0.08, 0)
		mini.rotation.y = PI * 1.25
		add_child(mini)
	
	match pad_type:
		"build_tower":
			col = Color(0.85, 0.50, 0.15, 0.85)
		"build_palisade":
			col = Color(0.28, 0.58, 0.28, 0.85)
		"build_barracks":
			col = Color(0.42, 0.28, 0.72, 0.85)
		"build_forge":
			col = Color(0.78, 0.28, 0.16, 0.85)
	base_pad_color = col
		
	if base_mesh:
		base_material = StandardMaterial3D.new()
		base_material.albedo_color = col
		base_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		base_material.roughness = 0.6
		base_mesh.material_override = base_material

func set_status(current_count: int, max_count: int, is_repair: bool = false, repair_cost: int = 10) -> void:
	current_items = current_count
	max_items = max_count
	is_repair_mode = is_repair
	
	if max_items > 0 and current_items >= max_items and not is_repair:
		is_locked = true
		locked_message = "MÁXIMO"
	else:
		is_locked = false
		if is_repair:
			current_cost = _calculate_discounted_cost(repair_cost)
			
	_update_ui()

func set_tutorial_locked(locked: bool) -> void:
	tutorial_locked = locked
	if cost_label_3d:
		cost_label_3d.visible = true
	if status_plate:
		status_plate.visible = true
	if not locked:
		# Evita uma compra acidental se o Rei terminar a etapa sobre este pad.
		is_king_present = false
		spend_timer = 0.0
	_update_ui()

func _process(delta: float) -> void:
	if not is_king_present or GameState.is_game_over or is_locked or tutorial_locked:
		return
	
	if current_paid < current_cost:
		spend_timer += delta
		if spend_timer >= spend_interval:
			spend_timer = 0.0
			if GameState.spend_stage_coins(1):
				current_paid += 1
				AudioManager.play_sfx("button_click")
				_update_ui()
				
				if current_paid >= current_cost:
					_finalize_purchase()

func _finalize_purchase() -> void:
	current_paid = 0
	AudioManager.play_sfx("recruit" if "recruit" in pad_type else "build")
	Art.pop_in(self)
	
	if not is_repair_mode:
		current_raw_cost += cost_increment_per_purchase
		current_cost = _calculate_discounted_cost(current_raw_cost)
		
	_update_ui()
	purchase_completed.emit(pad_type)

func _get_pad_title() -> String:
	var lang: String = I18n.language
	if is_repair_mode:
		if lang == "en":
			return "🛠️ Repair Walls"
		if lang == "es":
			return "🛠️ Reparar Muros"
		return "🛠️ Reparar Muros"
	match pad_type:
		"recruit_archer":
			if lang == "en":
				return "🏹 Archer"
			if lang == "es":
				return "🏹 Arquero"
			return "🏹 Arqueiro"
		"build_palisade":
			if lang == "en":
				return "🪵 Palisade (Wall)"
			if lang == "es":
				return "🪵 Empalizada (Muro)"
			return "🪵 Paliçada (Muro)"
		"build_tower":
			if lang == "en":
				return "🏰 Watchtower"
			if lang == "es":
				return "🏰 Torre de Vigía"
			return "🏰 Torre de Vigia"
		"build_forge":
			if lang == "en":
				return "⚒️ Forge (+Damage)"
			if lang == "es":
				return "⚒️ Forja (+Daño)"
			return "⚒️ Forja (+Dano)"
		"build_barracks":
			if lang == "en":
				return "⛺ Barracks (+Troops)"
			if lang == "es":
				return "⛺ Cuartel (+Tropas)"
			return "⛺ Quartel (+Tropas)"
	return pad_type

func _get_locked_label() -> String:
	if I18n.language == "en":
		return "🔒 Locked"
	return "🔒 Bloqueado"

func _update_ui() -> void:
	if not cost_label_3d:
		return
	var title := _get_pad_title()
	var remaining_cost := maxi(0, current_cost - current_paid)
	var can_afford: bool = GameState.stage_coins >= remaining_cost
	if base_material:
		var c := base_pad_color
		c.a = 0.25 if tutorial_locked else 0.85
		base_material.albedo_color = c
	var rim_mesh := get_node_or_null("RimMesh") as VisualInstance3D
	var brackets := get_node_or_null("CornerBrackets") as Node3D
	if brackets:
		brackets.visible = not tutorial_locked
	if rim_mesh:
		rim_mesh.visible = not tutorial_locked
	if status_material:
		if tutorial_locked:
			status_material.albedo_color = Color(0.18, 0.19, 0.22, 0.55)
		else:
			status_material.albedo_color = Color("#24452D") if can_afford else Color("#45484D")
	if cost_material:
		cost_material.albedo_color = Color("#FFC93C") if can_afford else Color("#9299A1")
		cost_material.emission = cost_material.albedo_color
	if tutorial_locked:
		cost_label_3d.text = "%s\n%s (🪙 %d)" % [title, _get_locked_label(), current_cost]
		cost_label_3d.modulate = Color(0.82, 0.85, 0.90, 0.85)
		I18n.protect(cost_label_3d)
		if fill_mesh:
			fill_mesh.scale.x = 0.01
			fill_mesh.scale.z = 0.01
		return
		
	if is_locked:
		var max_word := "MÁX" if I18n.language == "es" else ("MAX" if I18n.language == "en" else "MÁXIMO")
		cost_label_3d.text = "%s\n%s" % [title, max_word]
		cost_label_3d.modulate = Color(0.55, 1.0, 0.55)
		I18n.protect(cost_label_3d)
		if fill_mesh:
			fill_mesh.scale.x = 1.0
			fill_mesh.scale.z = 1.0
		return
		
	var cost_line := ("🪙 %d/%d" % [current_paid, current_cost]) if current_paid > 0 else ("🪙 %d" % current_cost)
	cost_label_3d.text = "%s\n%s" % [title, cost_line]
	I18n.protect(cost_label_3d)
	if is_repair_mode:
		cost_label_3d.modulate = Color(1.0, 0.85, 0.3)
	else:
		if can_afford:
			# Dourado/creme vivo: pode pagar!
			cost_label_3d.modulate = Color(1.0, 0.95, 0.70, 1.0) # #FFF3D6
		else:
			# Cinza desaturado: saldo insuficiente
			cost_label_3d.modulate = Color(0.75, 0.78, 0.82, 0.88)
	
	if fill_mesh:
		var ratio = float(current_paid) / float(maxi(1, current_cost))
		fill_mesh.scale.x = clampf(ratio, 0.01, 1.0)
		fill_mesh.scale.z = clampf(ratio, 0.01, 1.0)

func _on_body_entered(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		is_king_present = true

func _on_body_exited(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		is_king_present = false
		spend_timer = 0.0
