extends Area3D

# VillageBuilding.gd - Controlador de edifício interativo na Vila do Rei
# Transforma o visual do edifício conforme o nível (estilo Clash of Clans)
# e detalha com clareza os bônus concedidos para o exército e para o Rei.

signal building_upgraded(building_id: String, new_level: int)

@export var building_id: String = "barracks"
@export var building_name: String = "Quartel Real"
@export var base_cost: int = 40
@export var cost_multiplier: float = 1.6
@export var max_level: int = 5

var current_level: int = 1

@onready var label_level: Label3D = $LabelLevel
@onready var label_upgrade: Label3D = $LabelUpgrade
@onready var visuals_container: Node3D = $Visuals

func _ready() -> void:
	_sync_level()
	body_entered.connect(_on_body_entered)

func _sync_level() -> void:
	var buildings = SaveManager.save_data.get("village_buildings", {})
	current_level = int(buildings.get(building_id, 1))
	_rebuild_visuals()
	_update_labels()

func get_upgrade_cost() -> int:
	return int(base_cost * pow(cost_multiplier, float(current_level - 1)))

func get_benefit_description() -> String:
	match building_id:
		"barracks":
			var cur_bonus = (current_level - 1) * 10
			var next_bonus = current_level * 10
			if current_level >= max_level:
				return "⚔️ Dano do Exército: +%d%% (MÁXIMO)" % cur_bonus
			return "⚔️ Dano: +%d%% ➔ Nível %d: +%d%%" % [cur_bonus, current_level + 1, next_bonus]
		"blacksmith":
			var cur_disc = (current_level - 1) * 5
			var next_disc = current_level * 5
			if current_level >= max_level:
				return "🔨 Desconto de Moedas: -%d%% (MÁXIMO)" % cur_disc
			return "🔨 Custo na Fase: -%d%% ➔ Nível %d: -%d%%" % [cur_disc, current_level + 1, next_disc]
		"stable":
			var cur_hp = (current_level - 1) * 20
			var next_hp = current_level * 20
			if current_level >= max_level:
				return "🐎 Rei Teodoro: +%d HP (MÁXIMO)" % cur_hp
			return "🐎 Rei: +%d HP ➔ Nível %d: +%d HP" % [cur_hp, current_level + 1, next_hp]
		"tavern":
			return "🍻 Taverna Real: Heróis de Batalha"
		"crown_wall":
			return "👑 Mural das 6 Estrelas da Coroa"
		_:
			return "Edifício do Reino"

func _update_labels() -> void:
	if label_level:
		var benefit_str = get_benefit_description()
		label_level.text = "🏛️ %s (Nível %d)\n%s" % [building_name, current_level, benefit_str]
	
	if label_upgrade:
		if current_level >= max_level or building_id == "crown_wall":
			label_upgrade.text = "⭐ NÍVEL MÁXIMO ATINGIDO"
			label_upgrade.modulate = Color(0.6, 0.95, 0.6)
		else:
			label_upgrade.text = "Melhorar: 🪙 %d Ouro Real\n(Aproxime-se para evoluir)" % get_upgrade_cost()
			label_upgrade.modulate = Color(1.0, 0.88, 0.25)

func _rebuild_visuals() -> void:
	if not visuals_container:
		visuals_container = $Visuals
	if not visuals_container:
		return
		
	# Limpa nós visuais anteriores
	for child in visuals_container.get_children():
		child.queue_free()
		
	# Constrói o modelo 3D proporcional ao nível (Evolução Estilo Clash of Clans!)
	if current_level <= 1:
		_build_level_1_cottage()
	elif current_level == 2:
		_build_level_2_stone_house()
	else:
		_build_level_3_castle_keep()

func _build_level_1_cottage() -> void:
	# Nível 1: Cabana de madeira rústica com vigas e telhado de madeira
	Art.box(visuals_container, Vector3(3.2, 0.3, 3.2), Vector3(0, 0.15, 0), Art.STONE)
	Art.box(visuals_container, Vector3(2.6, 1.8, 2.6), Vector3(0, 1.15, 0), Art.WOOD_LIGHT)
	Art.roof(visuals_container, Vector3(3.1, 1.4, 3.1), Vector3(0, 2.7, 0), Art.WOOD)
	# Porta de madeira
	Art.box(visuals_container, Vector3(0.7, 1.2, 0.1), Vector3(0, 0.85, 1.35), Art.WOOD_DARK)
	# Janela pequena
	Art.box(visuals_container, Vector3(0.5, 0.5, 0.1), Vector3(0.7, 1.3, 1.35), Color(1.0, 0.9, 0.4))

func _build_level_2_stone_house() -> void:
	# Nível 2: Casa sólida de alvenaria e pedra com telhado vermelho e chaminé
	Art.box(visuals_container, Vector3(3.6, 0.4, 3.6), Vector3(0, 0.2, 0), Art.STONE_DARK)
	Art.box(visuals_container, Vector3(3.0, 2.2, 3.0), Vector3(0, 1.4, 0), Art.WHITE)
	Art.roof(visuals_container, Vector3(3.5, 1.6, 3.5), Vector3(0, 3.3, 0), Art.ROYAL_RED)
	# Porta de carvalho com arco
	Art.box(visuals_container, Vector3(0.8, 1.4, 0.12), Vector3(0, 0.95, 1.55), Art.WOOD_DARK)
	# Chaminé com fumaça
	Art.box(visuals_container, Vector3(0.6, 1.8, 0.6), Vector3(-0.9, 3.2, -0.6), Art.STONE)
	# Janelas duplas iluminadas
	Art.box(visuals_container, Vector3(0.5, 0.6, 0.1), Vector3(-0.8, 1.5, 1.55), Color(1.0, 0.92, 0.45))
	Art.box(visuals_container, Vector3(0.5, 0.6, 0.1), Vector3(0.8, 1.5, 1.55), Color(1.0, 0.92, 0.45))

func _build_level_3_castle_keep() -> void:
	# Nível 3+: Torreão de castelo fortificado com ameias, estandartes e bandeira
	Art.box(visuals_container, Vector3(4.0, 0.5, 4.0), Vector3(0, 0.25, 0), Art.STONE_DARK)
	Art.box(visuals_container, Vector3(3.4, 2.8, 3.4), Vector3(0, 1.75, 0), Art.STONE)
	# 4 Torreões nos cantos
	Art.cyl(visuals_container, 0.45, 0.45, 3.4, Vector3(-1.6, 1.7, -1.6), Art.STONE_DARK, 8)
	Art.cyl(visuals_container, 0.45, 0.45, 3.4, Vector3(1.6, 1.7, -1.6), Art.STONE_DARK, 8)
	Art.cyl(visuals_container, 0.45, 0.45, 3.4, Vector3(-1.6, 1.7, 1.6), Art.STONE_DARK, 8)
	Art.cyl(visuals_container, 0.45, 0.45, 3.4, Vector3(1.6, 1.7, 1.6), Art.STONE_DARK, 8)
	# Ameias / Merlões de castelo no topo
	Art.box(visuals_container, Vector3(3.6, 0.4, 3.6), Vector3(0, 3.3, 0), Art.STONE_DARK)
	Art.roof(visuals_container, Vector3(3.2, 1.8, 3.2), Vector3(0, 4.2, 0), Art.ROYAL_BLUE)
	# Mastro com bandeira real
	Art.cyl(visuals_container, 0.05, 0.05, 1.6, Vector3(0, 5.5, 0), Art.WOOD, 6)
	Art.box(visuals_container, Vector3(0.9, 0.45, 0.06), Vector3(0.45, 5.8, 0), Art.GOLD)
	# Portal de ferro
	Art.box(visuals_container, Vector3(1.1, 1.6, 0.15), Vector3(0, 1.05, 1.75), Art.STONE_DARK)

func try_upgrade() -> bool:
	if current_level >= max_level or building_id == "crown_wall":
		return false
	
	var cost = get_upgrade_cost()
	if SaveManager.spend_gold(cost):
		current_level += 1
		SaveManager.save_data["village_buildings"][building_id] = current_level
		SaveManager.save_game()
		
		AudioManager.play_sfx("build")
		_rebuild_visuals()
		_update_labels()
		
		Art.pop_in(self)
		Art.dust_puff(get_parent(), global_position + Vector3(0, 2.0, 0), 24)
		
		building_upgraded.emit(building_id, current_level)
		return true
	else:
		AudioManager.play_sfx("button_click")
		return false

func _on_body_entered(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		if current_level < max_level and SaveManager.get_gold() >= get_upgrade_cost():
			try_upgrade()
