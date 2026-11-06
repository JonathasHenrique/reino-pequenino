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
	if label_upgrade:
		label_upgrade.visible = false
	_sync_level()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
				return "⚔ Dano do Exército: +%d%% (MÁXIMO)" % cur_bonus
			return "⚔ Dano: +%d%% ➔ Nível %d: +%d%%" % [cur_bonus, current_level + 1, next_bonus]
		"blacksmith":
			var cur_disc = (current_level - 1) * 5
			var next_disc = current_level * 5
			if current_level >= max_level:
				return "Desconto de Moedas: -%d%% (MÁXIMO)" % cur_disc
			return "Custo na Fase: -%d%% ➔ Nível %d: -%d%%" % [cur_disc, current_level + 1, next_disc]
		"stable":
			var cur_hp = (current_level - 1) * 20
			var next_hp = current_level * 20
			if current_level >= max_level:
				return "Rei Teodoro: +%d HP (MÁXIMO)" % cur_hp
			return "Rei: +%d HP ➔ Nível %d: +%d HP" % [cur_hp, current_level + 1, next_hp]
		"tavern":
			return "Taverna Real: Heróis de Batalha"
		"crown_wall":
			return "Mural das 6 Estrelas da Coroa"
		_:
			return "Edifício do Reino"

func _update_labels() -> void:
	if label_level:
		label_level.text = "%s · Nível %d" % [building_name, current_level]
		var top := 5.4
		if building_id in ["barracks", "blacksmith", "stable", "tavern"]:
			top = 9.0 if current_level >= 2 else 7.4
		label_level.position.y = top
		label_level.no_depth_test = true
		label_level.render_priority = 10
		label_level.outline_render_priority = 9
		if label_upgrade:
			label_upgrade.position.y = top - 1.1
	
	if label_upgrade:
		if current_level >= max_level or building_id == "crown_wall":
			label_upgrade.text = get_benefit_description() + "\nNÍVEL MÁXIMO"
			label_upgrade.modulate = Color(0.6, 0.95, 0.6)
		else:
			label_upgrade.text = "%s\nPróximo nível · %d ouro" % [get_benefit_description(), get_upgrade_cost()]
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
	if building_id in ["barracks", "blacksmith", "stable", "tavern"]:
		_build_modular_house()
	elif current_level <= 1:
		_build_level_1_cottage()
	elif current_level == 2:
		_build_level_2_stone_house()
	else:
		_build_level_3_castle_keep()

func _build_modular_house() -> void:
	var footprints := {
		"barracks": Vector2i(6, 6),
		"blacksmith": Vector2i(4, 4),
		"stable": Vector2i(4, 6),
		"tavern": Vector2i(6, 6),
	}
	var styles := {
		"barracks": "plaster",
		"blacksmith": "brick",
		"stable": "plaster",
		"tavern": "brick",
	}
	var footprint: Vector2i = footprints.get(building_id, Vector2i(4, 4))
	var roof_tints := {
		"barracks": Color(0.92, 0.84, 0.78),
		"blacksmith": Color(0.78, 0.72, 0.70),
		"stable": Color(0.90, 0.95, 0.82),
		"tavern": Color(1.0, 0.92, 0.82),
	}
	load("res://scripts/village/ModularHouse.gd").build(visuals_container, footprint, str(styles.get(building_id, "plaster")), current_level, "south", roof_tints.get(building_id, Color.WHITE))
	visuals_container.rotation.y = atan2(-global_position.x, -global_position.z)
	visuals_container.scale = Vector3.ONE * 0.92

	var collider := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collider and collider.shape is BoxShape3D:
		var box := collider.shape as BoxShape3D
		box.size = Vector3(float(footprint.x) + 0.8, 3.0, float(footprint.y) + 0.8)
		collider.position = Vector3(0, 1.5, 0)

	load("res://scripts/core/StaticMeshMerger.gd").merge_subtree(visuals_container, ["Label3D"], false, true)

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
		if label_upgrade:
			label_upgrade.visible = true
		if current_level < max_level and SaveManager.get_gold() >= get_upgrade_cost():
			try_upgrade()

func _on_body_exited(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		if label_upgrade:
			label_upgrade.visible = false
