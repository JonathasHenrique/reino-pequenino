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

func _ready() -> void:
	current_cost = base_cost
	if cost_label_3d:
		cost_label_3d.font = UI_FONT
	_setup_pad_visuals()
	_update_ui()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.coins_changed.connect(func(_c): _update_ui())

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
	
	if emblems:
		var bow = emblems.get_node_or_null("BowEmblem")
		var tower = emblems.get_node_or_null("TowerEmblem")
		var palisade = emblems.get_node_or_null("PalisadeEmblem")
		var forge = emblems.get_node_or_null("ForgeEmblem")
		
		if bow: bow.visible = (pad_type == "recruit_archer")
		if tower: tower.visible = (pad_type == "build_tower")
		if palisade: palisade.visible = (pad_type == "build_palisade")
		if forge: forge.visible = (pad_type == "build_forge")
	
	match pad_type:
		"build_tower":
			col = Color(0.85, 0.50, 0.15, 0.85)
		"build_palisade":
			col = Color(0.28, 0.58, 0.28, 0.85)
		"build_barracks":
			col = Color(0.42, 0.28, 0.72, 0.85)
		"build_forge":
			col = Color(0.78, 0.28, 0.16, 0.85)
		
	if base_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = col
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.6
		base_mesh.material_override = mat

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
			current_cost = repair_cost
			
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
	
	var discount = 0.0
	if SaveManager.save_data.get("selected_hero") == "marta":
		discount = 0.15
	
	if not is_repair_mode:
		current_cost = maxi(3, int((current_cost + cost_increment_per_purchase) * (1.0 - discount)))
		
	_update_ui()
	purchase_completed.emit(pad_type)

func _update_ui() -> void:
	if not cost_label_3d:
		return
	var remaining_cost := maxi(0, current_cost - current_paid)
	var can_afford: bool = GameState.stage_coins >= remaining_cost
	if status_material:
		status_material.albedo_color = Color("#24452D") if can_afford else Color("#45484D")
	if cost_material:
		cost_material.albedo_color = Color("#FFC93C") if can_afford else Color("#9299A1")
		cost_material.emission = cost_material.albedo_color
	if tutorial_locked:
		cost_label_3d.text = str(current_cost)
		cost_label_3d.modulate = Color(0.62, 0.66, 0.70, 0.92)
		if fill_mesh:
			fill_mesh.scale.x = 0.01
			fill_mesh.scale.z = 0.01
		return
		
	if is_locked:
		cost_label_3d.text = "MAX"
		cost_label_3d.modulate = Color(0.55, 1.0, 0.55)
		if fill_mesh:
			fill_mesh.scale.x = 1.0
			fill_mesh.scale.z = 1.0
		return
		
	if is_repair_mode:
		if current_paid > 0:
			cost_label_3d.text = "%d/%d" % [current_paid, current_cost]
		else:
			cost_label_3d.text = str(current_cost)
		cost_label_3d.modulate = Color(1.0, 0.85, 0.3)
	else:
		if current_paid > 0:
			cost_label_3d.text = "%d/%d" % [current_paid, current_cost]
		else:
			cost_label_3d.text = str(current_cost)
				
		if can_afford:
			# Dourado/creme vivo: pode pagar!
			cost_label_3d.modulate = Color(1.0, 0.95, 0.70, 1.0) # #FFF3D6
		else:
			# Cinza desaturado: saldo insuficiente
			cost_label_3d.modulate = Color(0.65, 0.68, 0.72, 0.80) # #8E959E
	
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
