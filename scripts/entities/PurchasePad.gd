extends Area3D

# PurchasePad.gd - Plataforma de Compra no Chão estilo Kingshot / Clash of Clans
# Decalque no piso com ícone stencil, cantos iluminados e badge de custo flutuante

signal purchase_completed(pad_type: String)

@export var pad_type: String = "recruit_archer"
@export var base_cost: int = 5
@export var cost_increment_per_purchase: int = 1
@export var spend_interval: float = 0.09 # Gasto dinâmico e responsivo

var current_cost: int = 5
var current_paid: int = 0
var is_king_present: bool = false
var spend_timer: float = 0.0

var is_locked: bool = false
var locked_message: String = ""

var current_items: int = 0
var max_items: int = 0
var is_repair_mode: bool = false

@onready var cost_label_3d: Label3D = $Label3D
@onready var floor_icon: Label3D = get_node_or_null("FloorIcon")
@onready var fill_mesh: MeshInstance3D = $FillProgress
@onready var base_mesh: MeshInstance3D = $BaseMesh

func _ready() -> void:
	current_cost = base_cost
	_setup_pad_visuals()
	_update_ui()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_pad_visuals() -> void:
	var icon = "🏹"
	var col = Color(0.15, 0.48, 0.85, 0.85)
	match pad_type:
		"build_tower":
			icon = "🗼"
			col = Color(0.85, 0.50, 0.15, 0.85)
		"build_palisade":
			icon = "🪵"
			col = Color(0.28, 0.58, 0.28, 0.85)
		"build_barracks":
			icon = "🏛️"
			col = Color(0.42, 0.28, 0.72, 0.85)
		"build_forge":
			icon = "⚒️"
			col = Color(0.78, 0.28, 0.16, 0.85)
			
	if floor_icon:
		floor_icon.text = icon
		
	if base_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = col
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.6
		base_mesh.set_surface_override_material(0, mat)

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

func _process(delta: float) -> void:
	if not is_king_present or GameState.is_game_over or is_locked:
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
			
	if is_locked:
		cost_label_3d.text = "✔️ MÁXIMO"
		cost_label_3d.modulate = Color(0.6, 1.0, 0.6)
		if fill_mesh:
			fill_mesh.scale.x = 1.0
			fill_mesh.scale.z = 1.0
		return
		
	if is_repair_mode:
		cost_label_3d.text = "🛠️ REPARAR (🪙 %d/%d)" % [current_paid, current_cost]
		cost_label_3d.modulate = Color(1.0, 0.78, 0.28)
	else:
		if current_paid > 0:
			cost_label_3d.text = "🪙 %d / %d" % [current_paid, current_cost]
		else:
			cost_label_3d.text = "🪙 %d" % current_cost
		cost_label_3d.modulate = Color(1.0, 0.95, 0.65)
	
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
