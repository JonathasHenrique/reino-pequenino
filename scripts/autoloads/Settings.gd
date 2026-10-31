extends Node

# Settings.gd - Gerenciador de Configurações do Reino Pequenino
# Salva preferências do jogador localmente em JSON

signal settings_changed()
signal retro_mode_toggled(enabled: bool)

const SETTINGS_PATH: String = "user://settings.json"

enum Difficulty {
	TRANQUILO = 0,
	CLASSICO = 1, # Padrão
	VETERANO = 2  # Sem dicas nos puzzles, maior desafio
}

var music_volume: float = 0.8
var sfx_volume: float = 0.9
var vibration_enabled: bool = true
var difficulty: Difficulty = Difficulty.CLASSICO
var retro_mode: bool = false
var language: String = "pt_BR"
var reduced_effects: bool = false # Acessibilidade / dispositivos mais simples

func _ready() -> void:
	load_settings()

func get_difficulty_name() -> String:
	match difficulty:
		Difficulty.TRANQUILO:
			return "tranquilo"
		Difficulty.VETERANO:
			return "veterano"
		_:
			return "classico"

func set_difficulty_by_name(diff_name: String) -> void:
	match diff_name.to_lower():
		"tranquilo":
			difficulty = Difficulty.TRANQUILO
		"veterano":
			difficulty = Difficulty.VETERANO
		_:
			difficulty = Difficulty.CLASSICO
	save_settings()

func set_retro_mode(enabled: bool) -> void:
	if retro_mode != enabled:
		retro_mode = enabled
		retro_mode_toggled.emit(retro_mode)
		save_settings()

func save_settings() -> void:
	var data: Dictionary = {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"vibration_enabled": vibration_enabled,
		"difficulty": int(difficulty),
		"retro_mode": retro_mode,
		"language": language,
		"reduced_effects": reduced_effects
	}
	var json_str: String = JSON.stringify(data, "\t")
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	settings_changed.emit()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()
	var test_json = JSON.new()
	var parse_result = test_json.parse(content)
	if parse_result == OK and typeof(test_json.data) == TYPE_DICTIONARY:
		var d = test_json.data
		music_volume = float(d.get("music_volume", music_volume))
		sfx_volume = float(d.get("sfx_volume", sfx_volume))
		vibration_enabled = bool(d.get("vibration_enabled", vibration_enabled))
		difficulty = int(d.get("difficulty", difficulty)) as Difficulty
		retro_mode = bool(d.get("retro_mode", retro_mode))
		language = str(d.get("language", language))
		reduced_effects = bool(d.get("reduced_effects", reduced_effects))

