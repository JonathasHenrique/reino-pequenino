extends Node

# I18n.gd - Traduções PT-BR / EN / ES aplicadas em tempo de execução.
# Converte textos já existentes (PT) usando os JSONs e um mapa extra de UI.

signal language_changed(code: String)

const FILES := {
	"pt_BR": "res://data/translations/strings_pt_br.json",
	"en": "res://data/translations/strings_en.json",
	"es": "res://data/translations/strings_es.json",
}

var language: String = "pt_BR"
var _flat: Dictionary = {}
var _pt_flat: Dictionary = {}
var _reverse: Dictionary = {}
var _extra: Dictionary = {}

func _ready() -> void:
	language = _normalize(Settings.language)
	_pt_flat = _load_flat("pt_BR")
	for key in _pt_flat:
		_reverse[str(_pt_flat[key])] = key
	_build_extra()
	_flat = _load_flat(language)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("apply_tree", get_tree().root)

func _normalize(code: String) -> String:
	var low := code.to_lower()
	if low.begins_with("en"):
		return "en"
	if low.begins_with("es"):
		return "es"
	return "pt_BR"

func _load_flat(code: String) -> Dictionary:
	var out := {}
	var file := FileAccess.open(str(FILES.get(code, FILES["pt_BR"])), FileAccess.READ)
	if file == null:
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return out
	for section in parsed:
		if typeof(parsed[section]) == TYPE_DICTIONARY:
			for key in parsed[section]:
				out["%s.%s" % [section, key]] = parsed[section][key]
	return out

func _build_extra() -> void:
	_add_extra("Defesa de Base, Exércitos & Minigames Retrô", "Base Defense, Armies & Retro Minigames", "Defensa de Base, Ejércitos y Minijuegos Retro")
	_add_extra("INICIAR JORNADA", "START JOURNEY", "COMENZAR AVENTURA")
	_add_extra("VILA REAL DO REI", "ROYAL VILLAGE", "VILLA REAL DEL REY")
	_add_extra("AJUSTES DO REINO", "KINGDOM SETTINGS", "AJUSTES DEL REINO")
	_add_extra("A Aventura das Seis Estrelas da Coroa Mãe", "The Adventure of the Six Crown Stars", "La Aventura de las Seis Estrellas de la Corona Madre")
	_add_extra("Ouro:", "Gold:", "Oro:")
	_add_extra("Estrelas da Coroa:", "Crown Stars:", "Estrellas de la Corona:")
	_add_extra("Álbum", "Album", "Álbum")
	_add_extra("Troféus", "Trophies", "Trofeos")
	_add_extra("JOGO PAUSADO", "GAME PAUSED", "JUEGO EN PAUSA")
	_add_extra("Retomar", "Resume", "Reanudar")
	_add_extra("Voltar à Vila", "Back to Village", "Volver a la Villa")
	_add_extra("Pausar jogo", "Pause game", "Pausar juego")
	_add_extra("Pular História ⏩", "Skip Story ⏩", "Saltar Historia ⏩")
	_add_extra("Avançar ➔", "Next ➔", "Siguiente ➔")
	_add_extra("Dona Zenaide • Ex-Comandante Real", "Grandma Zenaide • Former Royal Commander", "Abuela Zenaide • Excomandante Real")
	_add_extra("Texto do diálogo aqui...", "Dialogue text here...", "Texto del diálogo aquí...")
	_add_extra("Mova o Rei", "Move the King", "Mueve al Rey")
	_add_extra("Arraste o joystick", "Drag the joystick", "Arrastra el joystick")
	_add_extra("Toque no pad ARQUEIRO", "Tap the ARCHER pad", "Toca el pad ARQUERO")
	_add_extra("Fique em cima do pad", "Stand on the pad", "Ponte sobre el pad")
	_add_extra("Pegue o capacete", "Grab the helmet", "Recoge el casco")
	_add_extra("Passe por cima dele", "Walk over it", "Pasa por encima")
	_add_extra("Venda ao Tobias", "Sell to Tobias", "Vende a Tobias")
	_add_extra("Entre no balcão dourado", "Enter the golden counter", "Entra en el mostrador dorado")
	_add_extra("Compre a paliçada", "Buy the palisade", "Compra la empalizada")
	_add_extra("Fique no pad PALIÇADA", "Stand on the PALISADE pad", "Ponte en el pad EMPALIZADA")
	_add_extra("TUTORIAL CONCLUÍDO", "TUTORIAL COMPLETE", "TUTORIAL COMPLETADO")
	_add_extra("Defenda o acampamento!", "Defend the camp!", "¡Defiende el campamento!")
	_add_extra("Use os pads e vença!", "Use the pads and win!", "¡Usa los pads y vence!")
	_add_extra("Quartel Real", "Royal Barracks", "Cuartel Real")
	_add_extra("Ferraria da Vila", "Village Forge", "Herrería de la Villa")
	_add_extra("Estábulo do Biscoito", "Biscuit's Stable", "Establo de Biscuito")
	_add_extra("Taverna dos Viajantes", "Travelers' Tavern", "Taberna de los Viajeros")
	_add_extra("Mural da Coroa Mãe", "Mother Crown Wall", "Muro de la Corona Madre")
	_add_extra("Moinho", "Mill", "Molino")
	_add_extra("Herói: Teodoro", "Hero: Teodoro", "Héroe: Teodoro")
	_add_extra("Dificuldade do Jogo:", "Game Difficulty:", "Dificultad del Juego:")
	_add_extra("Volume da Música:", "Music Volume:", "Volumen de la Música:")
	_add_extra("Efeitos Sonoros:", "Sound Effects:", "Efectos de Sonido:")
	_add_extra("Vibração no Celular:", "Phone Vibration:", "Vibración del Teléfono:")
	_add_extra("Modo Retrô (Tela Vintage):", "Retro Mode (Vintage Screen):", "Modo Retro (Pantalla Vintage):")
	_add_extra("Ativar Filtro CRT & Chiptune", "Enable CRT Filter & Chiptune", "Activar Filtro CRT y Chiptune")
	_add_extra("Reduzir Efeitos Visuais:", "Reduce Visual Effects:", "Reducir Efectos Visuales:")
	_add_extra("Acessibilidade / Desempenho", "Accessibility / Performance", "Accesibilidad / Rendimiento")
	_add_extra("Idioma / Language:", "Language / Idioma:", "Idioma / Language:")
	_add_extra("Idioma:", "Language:", "Idioma:")
	_add_extra("Salvar e Fechar", "Save and Close", "Guardar y Cerrar")
	_add_extra("Veterano (Sem Dicas & Desafio Alto)", "Veteran (No Hints & High Challenge)", "Veterano (Sin Pistas y Gran Desafío)")
	_add_extra("VITÓRIA GLORIOSA!", "GLORIOUS VICTORY!", "¡VICTORIA GLORIOSA!")
	_add_extra("REAGRUPAR O REINO!", "RALLY THE REALM!", "¡REAGRUPAR EL REINO!")
	_add_extra("Vila Real", "Royal Village", "Villa Real")
	_add_extra("Próxima Fase ➔", "Next Stage ➔", "Siguiente Fase ➔")
	_add_extra("Tentar de Novo", "Try Again", "Intentar de Nuevo")
	_add_extra("⚔️ Tentar de Novo", "⚔️ Try Again", "⚔️ Intentar de Nuevo")
	_add_extra("🏰 Vila Real", "🏰 Royal Village", "🏰 Villa Real")
	_add_extra("TENDA DO MERCADOR REAL", "ROYAL MERCHANT TENT", "TIENDA DEL MERCADOR REAL")
	_add_extra("Restaurar Compras", "Restore Purchases", "Restaurar Compras")
	_add_extra("TROFÉUS DO REINO", "KINGDOM TROPHIES", "TROFEOS DEL REINO")
	_add_extra("Voltar", "Back", "Volver")
	_add_extra("ÁLBUM DE FIGURINHAS DA COROA", "CROWN STICKER ALBUM", "ÁLBUM DE PEGATINAS DE LA CORONA")
	_add_extra("Fechar Álbum", "Close Album", "Cerrar Álbum")
	_add_extra("Ouro Real Permanente", "Permanent Royal Gold", "Oro Real Permanente")
	_add_extra("⚔ Batalha", "⚔ Battle", "⚔ Batalla")

func _add_extra(pt: String, en: String, es: String) -> void:
	_extra[pt] = {"en": en, "es": es}

func t_key(key: String) -> String:
	if _flat.has(key):
		return str(_flat[key])
	return str(_pt_flat.get(key, key))

func tr_text(text: String) -> String:
	if language == "pt_BR" or text.strip_edges() == "":
		return text
	var key: String = str(_reverse.get(text, ""))
	if key != "" and _flat.has(key):
		return str(_flat[key])
	if _extra.has(text):
		return str(_extra[text].get(language, text))
	return _pattern(text)

func _pattern(text: String) -> String:
	var s := text
	var pairs: Array = []
	if language == "en":
		pairs = [
			["Estrelas da Coroa", "Crown Stars"], ["Mural da Coroa Mãe", "Mother Crown Wall"],
			["Ferraria da Vila", "Village Forge"], ["Estábulo do Biscoito", "Biscuit's Stable"],
			["Taverna dos Viajantes", "Travelers' Tavern"], ["Quartel Real", "Royal Barracks"],
			["Vida do Rei", "King Health"], ["Próximo nível", "Next level"], ["Próximo", "Next"],
			["TUTORIAL CONCLUÍDO", "TUTORIAL COMPLETE"], ["JOGO PAUSADO", "GAME PAUSED"],
			["Onda", "Wave"], ["Nível", "Level"], ["Herói", "Hero"], ["Batalha", "Battle"],
			["Fase", "Stage"], ["Ouro", "Gold"], ["Moedas", "Coins"], ["Vida", "Health"],
			["Dano", "Damage"], ["Tropas", "Troops"], ["MÁXIMO", "MAX"], ["Moinho", "Mill"],
			["ouro", "gold"], ["Biscoito", "Biscuit"], ["Dona Zenaide", "Grandma Zenaide"],
			["Rei Teodoro", "King Theodoro"],
		]
	else:
		pairs = [
			["Estrelas da Coroa", "Estrellas de la Corona"], ["Mural da Coroa Mãe", "Muro de la Corona Madre"],
			["Ferraria da Vila", "Herrería de la Villa"], ["Estábulo do Biscoito", "Establo de Biscuito"],
			["Taverna dos Viajantes", "Taberna de los Viajeros"], ["Quartel Real", "Cuartel Real"],
			["Vida do Rei", "Vida del Rey"], ["Próximo nível", "Siguiente nivel"], ["Próximo", "Siguiente"],
			["TUTORIAL CONCLUÍDO", "TUTORIAL COMPLETADO"], ["JOGO PAUSADO", "JUEGO EN PAUSA"],
			["Onda", "Ola"], ["Nível", "Nivel"], ["Herói", "Héroe"], ["Batalha", "Batalla"],
			["Fase", "Fase"], ["Ouro", "Oro"], ["Moedas", "Monedas"], ["Vida", "Vida"],
			["Dano", "Daño"], ["Tropas", "Tropas"], ["MÁXIMO", "MAXIMO"], ["Moinho", "Molino"],
			["ouro", "oro"], ["Biscoito", "Biscuito"], ["Dona Zenaide", "Abuela Zenaide"],
			["Rei Teodoro", "Rey Teodoro"],
		]
	for pair in pairs:
		s = s.replace(str(pair[0]), str(pair[1]))
	return s

func apply_text(node: Node) -> void:
	if node == null:
		return
	var text := ""
	if node is Label or node is Button or node is CheckBox or node is RichTextLabel:
		text = str(node.get("text"))
	elif node is Label3D:
		text = str(node.get("text"))
	else:
		return
	if text == "":
		return
	if not node.has_meta("i18n_pt"):
		node.set_meta("i18n_pt", text)
	var base := str(node.get_meta("i18n_pt"))
	var translated := tr_text(base)
	if node is Label3D:
		node.set("text", translated)
	else:
		node.set("text", translated)

func protect(node: Node) -> void:
	if node == null:
		return
	var text := ""
	if node is Label or node is Button or node is CheckBox or node is RichTextLabel or node is Label3D:
		text = str(node.get("text"))
	node.set_meta("i18n_pt", text)

func set_text(node: Node, pt_text: String) -> void:
	if node == null:
		return
	node.set_meta("i18n_pt", pt_text)
	var translated := tr_text(pt_text)
	if node is Label3D:
		node.set("text", translated)
	else:
		node.set("text", translated)

func apply_tree(root: Node) -> void:
	if root == null:
		return
	apply_text(root)
	for child in root.get_children():
		apply_tree(child)

func _on_node_added(node: Node) -> void:
	if node is Control or node is Label3D:
		call_deferred("apply_text", node)

func set_language(code: String) -> void:
	language = _normalize(code)
	Settings.language = language
	Settings.save_settings()
	_flat = _load_flat(language)
	apply_tree(get_tree().root)
	language_changed.emit(language)
