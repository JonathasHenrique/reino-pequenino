extends Node3D

@export var imported_name: String = "ImportedRider"
# O Warrior CC0 é o corpo do Rei; ficam por cima só a coroa e a capa procedurais.
const CUSTOM_DETAILS: Array[String] = ["Crown", "Cape"]

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
	imported.rotation.y = PI
	load("res://scripts/effects/ChibiFace.gd").attach(imported, false, Color(0.27, 0.17, 0.11))
