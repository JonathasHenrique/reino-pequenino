extends Control

# IntroCutscene.gd - Abertura narrativa com ilustrações, fade e transição.

signal intro_completed()

const ILLUSTRATIONS := [
	"res://assets/ui/illustrations/prologue_1.png",
	"res://assets/ui/illustrations/prologue_2.png",
	"res://assets/ui/illustrations/prologue_3.png",
]
const ILLUSTRATIONS_FALLBACK := [
	"res://assets/ui/illustrations/prologue_1.jpeg",
	"res://assets/ui/illustrations/prologue_2.jpeg",
	"res://assets/ui/illustrations/prologue3.jpeg",
]

@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var skip_button: Button = $SkipButton
@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel

var _front: TextureRect = null
var _back: TextureRect = null
var _current_image: int = -1
var _finishing: bool = false

func _ready() -> void:
	AudioManager.play_music("prologue")
	_setup_illustrations()
	_style_texts()
	I18n.language_changed.connect(func(_code: String): _style_texts())
	if skip_button:
		skip_button.custom_minimum_size = Vector2(170.0, 46.0)
		skip_button.add_theme_font_size_override("font_size", 18)
		skip_button.pressed.connect(_on_skip_pressed)
	if dialogue_box:
		dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
		dialogue_box.line_changed.connect(_on_line_changed)
	_start_cutscene()

func _setup_illustrations() -> void:
	var shader: Shader = load("res://assets/shaders/story_illustration.gdshader")
	_front = _make_illustration(shader)
	_back = _make_illustration(shader)
	add_child(_front)
	move_child(_front, 0)
	add_child(_back)
	move_child(_back, 1)
	_back.modulate.a = 0.0
	var bg := get_node_or_null("Background") as CanvasItem
	if bg:
		bg.modulate.a = 0.32

func _make_illustration(shader: Shader) -> TextureRect:
	var rect := TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	return rect

func _style_texts() -> void:
	if title_label:
		title_label.text = I18n.t_key("ui.game_title")
		title_label.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.03))
		title_label.add_theme_constant_override("outline_size", 10)
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		title_label.add_theme_constant_override("shadow_offset_y", 5)
	if subtitle_label:
		subtitle_label.text = I18n.t_key("ui.game_subtitle")
		subtitle_label.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.03))
		subtitle_label.add_theme_constant_override("outline_size", 5)
	if skip_button:
		I18n.set_text(skip_button, "Pular História ⏩")

func _story_lines() -> Array[Dictionary]:
	var lang := I18n.language
	if lang == "en":
		return [
			{"speaker": "Grandma Zenaide", "icon": "👵", "text": "Theodoro! The Mother Crown is gone!", "image": 0},
			{"speaker": "King Theodoro", "icon": "👑", "text": "Biscuit thought it was oats!", "image": 0},
			{"speaker": "Grandma Zenaide", "icon": "👵", "text": "Baron Ash took the 6 Stars!", "image": 1},
			{"speaker": "King Theodoro", "icon": "👑", "text": "Let's get them all back!", "image": 1},
			{"speaker": "Grandma Zenaide", "icon": "👵", "text": "Grab your sword and archers!", "image": 2},
		]
	if lang == "es":
		return [
			{"speaker": "Abuela Zenaide", "icon": "👵", "text": "¡Teodoro! ¡La Corona Madre desapareció!", "image": 0},
			{"speaker": "Rey Teodoro", "icon": "👑", "text": "¡Biscuito creyó que era avena!", "image": 0},
			{"speaker": "Abuela Zenaide", "icon": "👵", "text": "¡El Barón se llevó las 6 Estrellas!", "image": 1},
			{"speaker": "Rey Teodoro", "icon": "👑", "text": "¡Vamos a recuperarlas!", "image": 1},
			{"speaker": "Abuela Zenaide", "icon": "👵", "text": "¡Toma tu espada y arqueros!", "image": 2},
		]
	return [
		{"speaker": "Dona Zenaide", "icon": "👵", "text": "Teodoro! A Coroa Mãe sumiu!", "image": 0},
		{"speaker": "Rei Teodoro", "icon": "👑", "text": "O Biscoito achou que era aveia!", "image": 0},
		{"speaker": "Dona Zenaide", "icon": "👵", "text": "O Barão levou as 6 Estrelas!", "image": 1},
		{"speaker": "Rei Teodoro", "icon": "👑", "text": "Vamos resgatar todas!", "image": 1},
		{"speaker": "Dona Zenaide", "icon": "👵", "text": "Pegue a espada e os arqueiros!", "image": 2},
	]

func _start_cutscene() -> void:
	if dialogue_box:
		dialogue_box.show_dialogue(_story_lines())

func _load_illustration(idx: int) -> Texture2D:
	var clamped := clampi(idx, 0, ILLUSTRATIONS.size() - 1)
	var png_path: String = ILLUSTRATIONS[clamped]
	if ResourceLoader.exists(png_path):
		var tex := load(png_path) as Texture2D
		if tex:
			return tex
	if FileAccess.file_exists(png_path):
		var img := Image.load_from_file(png_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	var jpg_path: String = ILLUSTRATIONS_FALLBACK[clamped]
	if ResourceLoader.exists(jpg_path):
		return load(jpg_path) as Texture2D
	return null

func _on_line_changed(_index: int, line: Dictionary) -> void:
	var image_index := int(line.get("image", 0))
	if image_index == _current_image:
		return
	_current_image = image_index
	var texture: Texture2D = _load_illustration(image_index)
	if _front.texture == null:
		_front.texture = texture
		_front.modulate.a = 1.0
		return
	_back.texture = texture
	_back.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_back, "modulate:a", 1.0, 0.45)
	tw.tween_callback(func():
		_front.texture = texture
		_front.modulate.a = 1.0
		_back.modulate.a = 0.0
	)

func _on_skip_pressed() -> void:
	_finish_intro()

func _on_dialogue_finished() -> void:
	_finish_intro()

func _finish_intro() -> void:
	if _finishing:
		return
	_finishing = true
	if skip_button:
		skip_button.disabled = true
	AudioManager.play_sfx("button_click")
	intro_completed.emit()
	GameState.start_stage(1)
	SceneTransition.change_scene("res://scenes/stages/StageMain.tscn")
