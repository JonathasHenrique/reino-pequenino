extends Area3D

# PurchasePad.gd - Plataforma de Compra no Chão
# Ao ficar sobre a plataforma, o Rei gasta moedas gradualmente até recrutar ou construir

signal purchase_completed(pad_type: String)

@export var pad_type: String = "recruit_archer"
@export var base_cost: int = 5
@export var cost_increment_per_purchase: int = 1
@export var spend_interval: float = 0.10 # Gasto suave e dinâmico

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
@onready var fill_mesh: MeshInstance3D = $FillProgress

func _ready() -> void:
	current_cost = base_cost
	_update_ui()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
		
	var type_name = "ARQUEIRO"
	var type_icon = "🏹"
	match pad_type:
		"build_tower":
			type_name = "TORRE"
			type_icon = "🗼"
		"build_palisade":
			type_name = "MURO"
			type_icon = "🪵"
		"build_barracks":
			type_name = "GUILDA"
			type_icon = "🏛️"
		"build_forge":
			type_name = "FERRARIA"
			type_icon = "⚒️"
			
	if is_locked:
		cost_label_3d.text = "%s %s [%d/%d]\n(COMPLETO)" % [type_icon, type_name, current_items, max_items]
		cost_label_3d.modulate = Color(0.7, 0.9, 0.7)
		if fill_mesh:
			fill_mesh.scale.x = 1.0
			fill_mesh.scale.z = 1.0
		return
		
	if is_repair_mode:
		cost_label_3d.text = "🛠️ REPARAR %s [%d/%d]\n🪙 %d / %d" % [type_name, current_items, max_items, current_paid, current_cost]
		cost_label_3d.modulate = Color(1.0, 0.8, 0.3)
	else:
		var count_str = ""
		if max_items > 0:
			count_str = " (%d/%d)" % [current_items, max_items]
			
		if current_paid > 0:
			cost_label_3d.text = "%s %s%s\n🪙 %d / %d" % [type_icon, type_name, count_str, current_paid, current_cost]
		else:
			cost_label_3d.text = "%s %s%s\n🪙 %d" % [type_icon, type_name, count_str, current_cost]
		cost_label_3d.modulate = Color(1, 0.96, 0.75)
	
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
