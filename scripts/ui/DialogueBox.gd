extends CanvasLayer

# DialogueBox.gd - Caixa de Diálogos com Humor em Duas Camadas
# Dona Zenaide narra e orienta o jovem Rei Teodoro com ternura e ironia refinada

signal dialogue_finished()
signal line_changed(index: int, line: Dictionary)

@onready var panel: PanelContainer = $Panel
@onready var portrait_label: Label = $Panel/HBox/PortraitPanel/Portrait
@onready var name_label: Label = $Panel/HBox/VBox/NameContainer/NameLabel
@onready var text_label: Label = $Panel/HBox/VBox/TextLabel
@onready var continue_btn: Button = $Panel/HBox/VBox/ContinueButton

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
		I18n.set_text(continue_btn, "Avançar ➔")
		continue_btn.pressed.connect(_on_continue_pressed)

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
	panel.offset_bottom = -28.0
	panel.offset_top = -28.0 - 185.0

func show_dialogue(lines: Array[Dictionary]) -> void:
	dialogue_queue = lines.duplicate()
	if dialogue_queue.is_empty():
		return
	is_active = true
	visible = true
	_display_next_line()

func _display_next_line() -> void:
	if dialogue_queue.is_empty():
		visible = false
		is_active = false
		dialogue_finished.emit()
		return
		
	var item = dialogue_queue.pop_front()
	if name_label:
		name_label.text = item.get("speaker", "Dona Zenaide")
		I18n.protect(name_label)
	if text_label:
		text_label.text = item.get("text", "")
		I18n.protect(text_label)
	if portrait_label:
		var speaker := str(item.get("speaker", "Zenaide"))
		var parts := speaker.split(" ", false)
		var last := str(parts[parts.size() - 1]) if parts.size() > 0 else speaker
		portrait_label.text = last.substr(0, 1).to_upper()
	_line_index += 1
	line_changed.emit(_line_index - 1, item)
	AudioManager.play_sfx("button_click")

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

