extends Node

# SaveManager.gd - Gerenciador de Salvamento Local do Reino Pequenino
# Salva em JSON local com número de versão e cópia de segurança automática (.bak)

signal save_loaded()
signal save_saved()
signal save_failed(error_message: String)
signal trophy_unlocked(trophy_id: String)
signal sticker_unlocked(sticker_id: String)

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
	else:
		check_and_unlock_achievements(false)
	
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

func save_game() -> bool:
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
	if not file:
		var message := "Não foi possível abrir o arquivo de progresso para gravação."
		push_error(message)
		save_failed.emit(message)
		return false
	file.store_string(json_str)
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		var message := "Não foi possível gravar o arquivo de progresso."
		push_error(message)
		save_failed.emit(message)
		return false
	save_saved.emit()
	return true

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

func _apply_stage_result(stage_id: int, stars: int, gold_earned: int) -> void:
	save_data["gold"] = get_gold() + gold_earned
	var stage_str = str(stage_id)
	var prev_stars = int(save_data.get("stage_stars", {}).get(stage_str, 0))
	if stars > prev_stars:
		save_data["stage_stars"][stage_str] = stars
	
	var current_unlocked = int(save_data.get("unlocked_stages", 1))
	if stage_id >= current_unlocked and stage_id < 60:
		save_data["unlocked_stages"] = stage_id + 1

func record_stage_result(stage_id: int, stars: int, gold_earned: int) -> bool:
	_apply_stage_result(stage_id, stars, gold_earned)
	check_and_unlock_achievements(true)
	return save_game()

func record_challenge_result(challenge_id: int, stars: int, gold_earned: int, hero_id: String, star_index: int) -> bool:
	_apply_stage_result(challenge_id, stars, gold_earned)
	_add_unique("unlocked_heroes", hero_id)
	save_data["crown_stars"] = maxi(int(save_data.get("crown_stars", 0)), star_index)
	_add_unique("stickers", "star_" + str(star_index))
	_add_unique("trophies", "challenge_" + str(challenge_id))
	match challenge_id:
		10:
			_add_unique("trophies", "catapult_master")
		20:
			_add_unique("trophies", "sudoku_wizard")
		30:
			_add_unique("trophies", "shield_hero")
		60:
			_add_unique("trophies", "full_crown")
	check_and_unlock_achievements(true)
	return save_game()

func check_and_unlock_achievements(show_toast: bool = true) -> Array[String]:
	var newly_unlocked_trophies: Array[String] = []
	var changed: bool = false
	var unlocked_stages: int = int(save_data.get("unlocked_stages", 1))
	var stage_stars: Dictionary = save_data.get("stage_stars", {}) if save_data.get("stage_stars") is Dictionary else {}
	var crown_stars: int = int(save_data.get("crown_stars", 0))
	var buildings: Dictionary = save_data.get("village_buildings", {}) if save_data.get("village_buildings") is Dictionary else {}
	var trophies: Array = save_data.get("trophies", []) if save_data.get("trophies") is Array else []
	var stickers: Array = save_data.get("stickers", []) if save_data.get("stickers") is Array else []

	# 1. Primeira Vitória Real (first_victory)
	var beat_stage_1: bool = unlocked_stages > 1 or int(stage_stars.get("1", 0)) > 0 or stage_stars.size() > 0
	if beat_stage_1 and not trophies.has("first_victory"):
		trophies.append("first_victory")
		newly_unlocked_trophies.append("first_victory")
		changed = true

	# 2. Mestre da Catapulta (catapult_master - Desafio 10)
	var beat_stage_10: bool = int(stage_stars.get("10", 0)) > 0 or unlocked_stages > 10 or trophies.has("challenge_10") or crown_stars >= 1
	if beat_stage_10 and not trophies.has("catapult_master"):
		trophies.append("catapult_master")
		newly_unlocked_trophies.append("catapult_master")
		changed = true

	# 3. Sábio dos Números (sudoku_wizard - Desafio 20)
	var beat_stage_20: bool = int(stage_stars.get("20", 0)) > 0 or unlocked_stages > 20 or trophies.has("challenge_20") or crown_stars >= 2
	if beat_stage_20 and not trophies.has("sudoku_wizard"):
		trophies.append("sudoku_wizard")
		newly_unlocked_trophies.append("sudoku_wizard")
		changed = true

	# 4. Escudo Inquebrável (shield_hero - Desafio 30)
	var beat_stage_30: bool = int(stage_stars.get("30", 0)) > 0 or unlocked_stages > 30 or trophies.has("challenge_30") or crown_stars >= 3
	if beat_stage_30 and not trophies.has("shield_hero"):
		trophies.append("shield_hero")
		newly_unlocked_trophies.append("shield_hero")
		changed = true

	# 5. Arquiteto do Vilarejo (village_architect - todos os edifícios melhoráveis >= nível 2)
	var core_buildings := ["barracks", "blacksmith", "stable", "tavern"]
	var all_upgraded: bool = true
	for b_id in core_buildings:
		if int(buildings.get(b_id, 1)) < 2:
			all_upgraded = false
			break
	if all_upgraded and not trophies.has("village_architect"):
		trophies.append("village_architect")
		newly_unlocked_trophies.append("village_architect")
		changed = true

	# 6. A Coroa Reunida (full_crown - Desafio 60 / 6 Estrelas)
	var beat_stage_60: bool = crown_stars >= 6 or int(stage_stars.get("60", 0)) > 0 or trophies.has("challenge_60")
	if beat_stage_60 and not trophies.has("full_crown"):
		trophies.append("full_crown")
		newly_unlocked_trophies.append("full_crown")
		changed = true

	# Figurinhas (star_1 a star_6):
	# star_1 liberada retroativamente ao vencer as primeiras fases/3 estrelas ou Mundo 1
	if beat_stage_1 and not stickers.has("star_1"):
		stickers.append("star_1")
		changed = true
		sticker_unlocked.emit("star_1")
	for w in range(2, 7):
		var st_id := "star_%d" % w
		var world_boss_stage := str(w * 10)
		var world_cleared: bool = int(stage_stars.get(world_boss_stage, 0)) > 0 or unlocked_stages > (w * 10) or crown_stars >= w
		if world_cleared and not stickers.has(st_id):
			stickers.append(st_id)
			changed = true
			sticker_unlocked.emit(st_id)

	if changed:
		save_data["trophies"] = trophies
		save_data["stickers"] = stickers
		save_game()
		for tid in newly_unlocked_trophies:
			trophy_unlocked.emit(tid)
		if show_toast and not newly_unlocked_trophies.is_empty():
			_show_trophy_toast(newly_unlocked_trophies[0])

	return newly_unlocked_trophies

func _show_trophy_toast(trophy_id: String) -> void:
	if not is_inside_tree():
		return
	var title_key := "trophies.%s_title" % trophy_id
	var t_name := I18n.t_key(title_key)
	if t_name == title_key:
		var fallback_names := {
			"first_victory": "Primeira Vitória Real",
			"catapult_master": "Mestre da Catapulta",
			"sudoku_wizard": "Sábio dos Números",
			"shield_hero": "Escudo Inquebrável",
			"village_architect": "Arquiteto do Vilarejo",
			"full_crown": "A Coroa Reunida"
		}
		t_name = I18n.tr_text(str(fallback_names.get(trophy_id, trophy_id)))
	var prefix := "🏆 TROFÉU DESBLOQUEADO: "
	if I18n.language == "en":
		prefix = "🏆 TROPHY UNLOCKED: "
	elif I18n.language == "es":
		prefix = "🏆 TROFEO DESBLOQUEADO: "

	var layer := CanvasLayer.new()
	layer.layer = 60
	get_tree().root.add_child(layer)

	var banner := PanelContainer.new()
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.anchor_top = 0.0
	banner.anchor_bottom = 0.0
	banner.offset_left = -280.0
	banner.offset_right = 280.0
	banner.offset_top = 18.0
	banner.offset_bottom = 82.0
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.24, 0.16, 0.05, 0.96)
	st.border_color = Color(1.0, 0.84, 0.22, 1.0)
	st.set_border_width_all(3)
	st.set_corner_radius_all(18)
	st.content_margin_left = 20.0
	st.content_margin_right = 20.0
	st.content_margin_top = 10.0
	st.content_margin_bottom = 10.0
	banner.add_theme_stylebox_override("panel", st)
	layer.add_child(banner)

	var lbl := Label.new()
	lbl.text = prefix + t_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.38))
	lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.02))
	lbl.add_theme_constant_override("outline_size", 5)
	I18n.protect(lbl)
	banner.add_child(lbl)

	banner.modulate.a = 0.0
	var tw := layer.create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.28)
	tw.tween_interval(2.6)
	tw.tween_property(banner, "modulate:a", 0.0, 0.35)
	tw.tween_callback(layer.queue_free)

func _add_unique(key: String, value: String) -> void:
	var values: Array = save_data.get(key, [])
	if not values.has(value):
		values.append(value)
		save_data[key] = values

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
