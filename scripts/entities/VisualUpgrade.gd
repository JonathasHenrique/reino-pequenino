extends Node

@export var visuals_path: NodePath = NodePath("../Visuals")
@export var imported_name: String = "ImportedCharacter"
@export var custom_overlays: PackedStringArray = []

func _ready() -> void:
	call_deferred("_swap_visuals")

func _swap_visuals() -> void:
	var visuals := get_node_or_null(visuals_path)
	if not visuals:
		return
	var imported := visuals.get_node_or_null(imported_name)
	if not imported:
		return
	for child in visuals.get_children():
		if child != imported and child is Node3D:
			child.visible = custom_overlays.has(str(child.name))
	imported.visible = true
