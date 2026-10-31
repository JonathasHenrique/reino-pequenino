extends CanvasLayer

# DialogueBox.gd - Caixa de Diálogos com Humor em Duas Camadas
# Dona Zenaide narra e orienta o jovem Rei Teodoro com ternura e ironia refinada

signal dialogue_finished()

@onready var portrait_label: Label = $Panel/HBox/Portrait
@onready var name_label: Label = $Panel/HBox/VBox/NameLabel
@onready var text_label: Label = $Panel/HBox/VBox/TextLabel
@onready var continue_btn: Button = $Panel/HBox/VBox/ContinueButton

var dialogue_queue: Array[Dictionary] = []
var is_active: bool = false

func _ready() -> void:
	visible = false
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)

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
	if text_label:
		text_label.text = item.get("text", "")
	if portrait_label:
		portrait_label.text = item.get("icon", "👵")
		
	AudioManager.play_sfx("button_click")

func _on_continue_pressed() -> void:
	_display_next_line()

func _input(event: InputEvent) -> void:
	if is_active and (event is InputEventScreenTouch or event is InputEventMouseButton):
		if event.pressed:
			_display_next_line()
			get_viewport().set_input_as_handled()

