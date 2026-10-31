extends Area3D

# VillageBuilding.gd - Controlador de edifício interativo na Vila do Rei
# Exibe nível atual, custo de melhoria instantânea e aplica melhorias sem timers

signal building_upgraded(building_id: String, new_level: int)

@export var building_id: String = "barracks"
@export var building_name: String = "Quartel Real"
@export var base_cost: int = 40
@export var cost_multiplier: float = 1.6
@export var max_level: int = 5

var current_level: int = 1

@onready var label_level: Label3D = $LabelLevel
@onready var label_upgrade: Label3D = $LabelUpgrade

func _ready() -> void:
	_sync_level()
	body_entered.connect(_on_body_entered)

func _sync_level() -> void:
	var buildings = SaveManager.save_data.get("village_buildings", {})
	current_level = int(buildings.get(building_id, 1))
	_update_labels()

func get_upgrade_cost() -> int:
	return int(base_cost * pow(cost_multiplier, float(current_level - 1)))

func _update_labels() -> void:
	if label_level:
		label_level.text = "%s\nNível %d" % [building_name, current_level]
	
	if label_upgrade:
		if current_level >= max_level:
			label_upgrade.text = "NÍVEL MÁXIMO"
			label_upgrade.modulate = Color(0.6, 0.9, 0.6)
		else:
			label_upgrade.text = "Melhorar: 🪙 %d Ouro" % get_upgrade_cost()
			label_upgrade.modulate = Color(1.0, 0.85, 0.2)

func try_upgrade() -> bool:
	if current_level >= max_level:
		return false
	
	var cost = get_upgrade_cost()
	if SaveManager.spend_gold(cost):
		current_level += 1
		SaveManager.save_data["village_buildings"][building_id] = current_level
		SaveManager.save_game()
		AudioManager.play_sfx("build")
		_update_labels()
		building_upgraded.emit(building_id, current_level)
		return true
	else:
		AudioManager.play_sfx("button_click")
		return false

func _on_body_entered(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		# Tenta melhorar automaticamente ao aproximar se o jogador tiver ouro suficiente
		if current_level < max_level and SaveManager.get_gold() >= get_upgrade_cost():
			try_upgrade()

