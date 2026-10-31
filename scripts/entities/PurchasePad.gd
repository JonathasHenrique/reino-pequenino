extends Area3D

# PurchasePad.gd - Plataforma de Compra no Chão
# Ao ficar sobre a plataforma, o Rei gasta moedas gradualmente até recrutar ou construir

signal purchase_completed(pad_type: String)

@export var pad_type: String = "recruit_archer" # recruit_archer, build_tower, build_palisade
@export var base_cost: int = 5
@export var cost_increment_per_purchase: int = 1
@export var spend_interval: float = 0.12 # Intervalo entre cada moeda gasta

var current_cost: int = 5
var current_paid: int = 0
var is_king_present: bool = false
var spend_timer: float = 0.0

@onready var cost_label_3d: Label3D = $Label3D
@onready var fill_mesh: MeshInstance3D = $FillProgress

func _ready() -> void:
	current_cost = base_cost
	_update_ui()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not is_king_present or GameState.is_game_over:
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
			else:
				# Sem moedas suficientes no momento
				pass

func _finalize_purchase() -> void:
	current_paid = 0
	AudioManager.play_sfx("recruit" if "recruit" in pad_type else "build")
	
	# Desconto da Marta, se ativa
	var discount = 0.0
	if SaveManager.save_data.get("selected_hero") == "marta":
		discount = 0.15
	
	current_cost = maxi(3, int((current_cost + cost_increment_per_purchase) * (1.0 - discount)))
	_update_ui()
	purchase_completed.emit(pad_type)

func _update_ui() -> void:
	if cost_label_3d:
		cost_label_3d.text = "%d / %d" % [current_paid, current_cost] if current_paid > 0 else str(current_cost)
	
	if fill_mesh:
		var ratio = float(current_paid) / float(current_cost)
		fill_mesh.scale.x = clampf(ratio, 0.01, 1.0)
		fill_mesh.scale.z = clampf(ratio, 0.01, 1.0)

func _on_body_entered(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		is_king_present = true

func _on_body_exited(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		is_king_present = false
		spend_timer = 0.0

