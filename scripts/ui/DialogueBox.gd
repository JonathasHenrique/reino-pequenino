extends CanvasLayer

# DialogueBox.gd - Caixa de Diálogos com Humor em Duas Camadas
# Dona Zenaide narra e orienta o jovem Rei Teodoro com ternura e ironia refinada

signal dialogue_finished()
signal line_changed(index: int, line: Dictionary)

@onready var panel: PanelContainer = $Panel
@onready var portrait_image: TextureRect = $Panel/HBox/PortraitPanel/PortraitImage
@onready var portrait_label: Label = $Panel/HBox/PortraitPanel/Portrait
@onready var name_label: Label = $Panel/HBox/VBox/NameContainer/NameLabel
@onready var text_label: Label = $Panel/HBox/VBox/TextLabel
@onready var continue_btn: Button = $Panel/HBox/VBox/ContinueButton

const PORTRAITS = {
	"zenaide": "res://assets/ui/portraits/zenaide.png",
	"teodoro": "res://assets/ui/portraits/teodoro.png",
	"tobias": "res://assets/ui/portraits/tobias.png",
	"marta": "res://assets/ui/portraits/marta.png",
	"barao": "res://assets/ui/portraits/barao.png"
}

var dialogue_queue: Array[Dictionary] = []
var is_active: bool = false
var _line_index: int = 0

func _ready() -> void:
	visible = false
	_layout_panel()
	get_viewport().size_changed.connect(_layout_panel)
	if continue_btn:
		continue_btn.custom_minimum_size = Vector2(190.0, 46.0)
		continue_btn.add_theme_font_size_override("font_size", 18)
		I18n.set_text(continue_btn, "Avançar >>")
		continue_btn.pressed.connect(_on_continue_pressed)

func _exit_tree() -> void:
	if is_active:
		GameState.set_dialogue_open(false)

func _layout_panel() -> void:
	if panel == null:
		return
	var view := get_viewport().get_visible_rect().size
	var width := minf(940.0, view.x * 0.9)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	# Subindo a posição Y do painel para nunca sobrepor o botão de ação/Grito de Coragem no canto inferior direito
	panel.offset_bottom = -135.0
	panel.offset_top = -135.0 - 180.0

func show_dialogue(lines: Array[Dictionary]) -> void:
	dialogue_queue = lines.duplicate()
	if dialogue_queue.is_empty():
		return
	is_active = true
	visible = true
	GameState.set_dialogue_open(true)
	_display_next_line()

func _display_next_line() -> void:
	if dialogue_queue.is_empty():
		visible = false
		is_active = false
		GameState.set_dialogue_open(false)
		dialogue_finished.emit()
		return
		
	var item = dialogue_queue.pop_front()
	if name_label:
		name_label.text = item.get("speaker", "Dona Zenaide")
		I18n.protect(name_label)
	if text_label:
		text_label.text = item.get("text", "")
		I18n.protect(text_label)
	var spk := str(item.get("speaker", "")).to_lower()
	var portrait_path := ""
	if item.has("portrait") and str(item.get("portrait")) != "":
		portrait_path = str(item.get("portrait"))
	elif "zenaide" in spk or "dona" in spk or "grandma" in spk or "abuela" in spk:
		portrait_path = PORTRAITS["zenaide"]
	elif "teodoro" in spk or "rei" in spk or "king" in spk or "theodoro" in spk or "rey" in spk:
		portrait_path = PORTRAITS["teodoro"]
	elif "tobias" in spk:
		portrait_path = PORTRAITS["tobias"]
	elif "marta" in spk:
		portrait_path = PORTRAITS["marta"]
	elif "bar" in spk: # barão / baron
		portrait_path = PORTRAITS["barao"]
	else:
		portrait_path = PORTRAITS["zenaide"]

	var tex: Texture2D = _load_portrait_texture(portrait_path)

	if portrait_image and tex:
		portrait_image.texture = tex
		portrait_image.visible = true
		if portrait_label:
			portrait_label.visible = false
	elif portrait_label:
		if portrait_image:
			portrait_image.visible = false
		portrait_label.visible = true
		if item.has("icon") and str(item.get("icon")).length() > 0 and str(item.get("icon")) != "Z":
			portrait_label.text = str(item.get("icon"))
		else:
			portrait_label.text = "👵"
	_line_index += 1
	line_changed.emit(_line_index - 1, item)
	AudioManager.play_sfx("button_click")

func _load_portrait_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			return tex
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func _on_continue_pressed() -> void:
	_display_next_line()

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			if panel and panel.get_global_rect().has_point(event.position):
				return
			_display_next_line()
			get_viewport().set_input_as_handled()

