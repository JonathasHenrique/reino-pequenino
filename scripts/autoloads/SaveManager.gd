extends Node

# SaveManager.gd - Gerenciador de Salvamento Local do Reino Pequenino
# Salva em JSON local com número de versão e cópia de segurança automática (.bak)

signal save_loaded()
signal save_saved()

const SAVE_PATH: String = "user://savegame.json"
const BACKUP_PATH: String = "user://savegame.bak"
const CURRENT_VERSION: int = 1

var save_data: Dictionary = {}

func _ready() -> void:
	load_game()

func get_default_data() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"player_name": "Teodoro",
		"gold": 50, # Ouro inicial para a vila
		"unlocked_stages": 1, # Fase 1 desbloqueada
		"stage_stars": {}, # Ex: {"1": 3, "2": 2}
		"crown_stars": 0, # De 0 a 6
		"unlocked_heroes": ["teodoro"],
		"selected_hero": "teodoro",
		"village_buildings": {
			"barracks": 1,
			"blacksmith": 1,
			"stable": 1,
			"mill": 1,
			"mage_tower": 0,
			"tavern": 1,
			"crown_wall": 1
		},
		"mill_stored_gold": 0,
		"mill_last_collection": Time.get_unix_time_from_system(),
		"trophies": [],
		"stickers": [],
		"skins_unlocked": ["crown_classic", "pony_biscoito"],
		"selected_crown_skin": "crown_classic",
		"selected_pony_skin": "pony_biscoito",
		"total_play_time": 0.0,
		"enemies_defeated": 0,
		"coins_collected": 0,
		"stage_1_tutorial_completed": false
	}

func load_game() -> void:
	var loaded = false
	if FileAccess.file_exists(SAVE_PATH):
		loaded = _try_load_file(SAVE_PATH)
	
	if not loaded and FileAccess.file_exists(BACKUP_PATH):
		push_warning("Aviso: Falha ao ler save primário. Tentando restaurar do backup...")
		loaded = _try_load_file(BACKUP_PATH)
	
	if not loaded:
		print("Criando novo arquivo de progresso padrão...")
		save_data = get_default_data()
		save_game()
	
	save_loaded.emit()

func _try_load_file(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err == OK and typeof(json.data) == TYPE_DICTIONARY:
		save_data = json.data
		_migrate_if_needed()
		return true
	return false

func _migrate_if_needed() -> void:
	var default = get_default_data()
	for key in default.keys():
		if not save_data.has(key):
			save_data[key] = default[key]

func save_game() -> void:
	# Antes de sobrescrever, cria backup se o arquivo atual for válido
	if FileAccess.file_exists(SAVE_PATH):
		var src = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if src:
			var content = src.get_as_text()
			src.close()
			var backup = FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if backup:
				backup.store_string(content)
				backup.close()

	var json_str = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		save_saved.emit()

# --- Métodos de Conveniência ---

func get_gold() -> int:
	return int(save_data.get("gold", 0))

func add_gold(amount: int) -> void:
	save_data["gold"] = get_gold() + amount
	save_game()

func spend_gold(amount: int) -> bool:
	var current = get_gold()
	if current >= amount:
		save_data["gold"] = current - amount
		save_game()
		return true
	return false

func is_stage_unlocked(stage_id: int) -> bool:
	return stage_id <= int(save_data.get("unlocked_stages", 1))

func record_stage_result(stage_id: int, stars: int, gold_earned: int) -> void:
	add_gold(gold_earned)
	var stage_str = str(stage_id)
	var prev_stars = int(save_data.get("stage_stars", {}).get(stage_str, 0))
	if stars > prev_stars:
		if not save_data.has("stage_stars"):
			save_data["stage_stars"] = {}
		save_data["stage_stars"][stage_str] = stars
	
	var current_unlocked = int(save_data.get("unlocked_stages", 1))
	if stage_id >= current_unlocked and stage_id < 60:
		save_data["unlocked_stages"] = stage_id + 1
	
	save_game()

func unlock_hero(hero_id: String) -> void:
	var list: Array = save_data.get("unlocked_heroes", [])
	if not list.has(hero_id):
		list.append(hero_id)
		save_data["unlocked_heroes"] = list
		save_game()

func unlock_crown_star(star_index: int) -> void:
	var current = int(save_data.get("crown_stars", 0))
	if star_index > current:
		save_data["crown_stars"] = star_index
		save_game()

func unlock_trophy(trophy_id: String) -> void:
	var trophies: Array = save_data.get("trophies", [])
	if not trophies.has(trophy_id):
		trophies.append(trophy_id)
		save_data["trophies"] = trophies
		save_game()

func unlock_sticker(sticker_id: String) -> void:
	var stickers: Array = save_data.get("stickers", [])
	if not stickers.has(sticker_id):
		stickers.append(sticker_id)
		save_data["stickers"] = stickers
		save_game()
