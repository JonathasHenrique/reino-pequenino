extends Area3D

# Mill.gd - Moinho de Vento e Fazenda da Vila
# Produz Ouro passivo ao longo do tempo (até um limite baseado no nível do moinho)

@export var base_rate_per_minute: float = 6.0 # 6 ouro por minuto no nível 1
@export var base_capacity: int = 100

var current_level: int = 1
var stored_gold: int = 0
var last_timestamp: int = 0

@onready var label_status: Label3D = $LabelStatus
@onready var blades_node: Node3D = $Visuals/Blades

func _ready() -> void:
	_sync_state()
	body_entered.connect(_on_body_entered)

func _sync_state() -> void:
	var buildings = SaveManager.save_data.get("village_buildings", {})
	current_level = int(buildings.get("mill", 1))
	
	stored_gold = int(SaveManager.save_data.get("mill_stored_gold", 0))
	last_timestamp = int(SaveManager.save_data.get("mill_last_collection", Time.get_unix_time_from_system()))
	
	_calculate_offline_accumulation()
	_update_label()

func _calculate_offline_accumulation() -> void:
	var now = Time.get_unix_time_from_system()
	var elapsed_seconds = max(0, now - last_timestamp)
	var rate_per_second = (base_rate_per_minute * (1.0 + (current_level - 1) * 0.4)) / 60.0
	var new_gold = int(elapsed_seconds * rate_per_second)
	
	var max_cap = base_capacity + (current_level - 1) * 50
	stored_gold = mini(max_cap, stored_gold + new_gold)
	
	SaveManager.save_data["mill_stored_gold"] = stored_gold
	SaveManager.save_data["mill_last_collection"] = now
	SaveManager.save_game()

func _process(delta: float) -> void:
	# Gira as pás do moinho suavemente
	if blades_node:
		blades_node.rotate_z(delta * 1.5)
	
	# Acumulação em tempo real
	var rate_per_second = (base_rate_per_minute * (1.0 + (current_level - 1) * 0.4)) / 60.0
	var max_cap = base_capacity + (current_level - 1) * 50
	
	if stored_gold < max_cap:
		var now = Time.get_unix_time_from_system()
		if now - last_timestamp >= 5: # Atualiza a cada 5 segundos
			var elapsed = now - last_timestamp
			var earned = int(elapsed * rate_per_second)
			if earned > 0:
				stored_gold = mini(max_cap, stored_gold + earned)
				last_timestamp = now
				SaveManager.save_data["mill_stored_gold"] = stored_gold
				SaveManager.save_data["mill_last_collection"] = now
				_update_label()

func _update_label() -> void:
	if label_status:
		var max_cap = base_capacity + (current_level - 1) * 50
		if stored_gold >= max_cap:
			label_status.text = "🌾 MOINHO (CHEIO!)\nToque para coletar: 🪙 %d Ouro" % stored_gold
			label_status.modulate = Color(1.0, 0.9, 0.2)
		else:
			label_status.text = "🌾 MOINHO (Nível %d)\nAcumulado: 🪙 %d / %d" % [current_level, stored_gold, max_cap]
			label_status.modulate = Color(0.9, 0.95, 0.9)

func collect_gold() -> int:
	if stored_gold <= 0:
		return 0
		
	var collected = stored_gold
	stored_gold = 0
	last_timestamp = Time.get_unix_time_from_system()
	
	SaveManager.save_data["mill_stored_gold"] = 0
	SaveManager.save_data["mill_last_collection"] = last_timestamp
	SaveManager.add_gold(collected)
	
	AudioManager.play_sfx("coin_pickup")
	_update_label()
	return collected

func _on_body_entered(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		collect_gold()

