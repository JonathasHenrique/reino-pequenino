extends Node3D

@export var imported_name: String = "ImportedRider"
const CUSTOM_DETAILS: Array[String] = ["Torso", "Belt", "SwordHilt", "Head", "Crown", "Cape"]

func _ready() -> void:
	call_deferred("_swap_rider")

func _swap_rider() -> void:
	var imported := get_node_or_null(imported_name)
	if not imported:
		return
	for child in get_children():
		if child != imported and child is Node3D:
			child.visible = CUSTOM_DETAILS.has(str(child.name))
	imported.visible = true
