extends Control

# EdgeIndicators.gd - Indicadores de seta na borda da tela
# Mostra a direção de aproximação dos inimigos fora do campo de visão

@export var margin: float = 36.0
var indicator_pool: Array[Label] = []
var max_indicators: int = 8

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	for i in range(max_indicators):
		var lbl = Label.new()
		lbl.text = "⚠️ ➔"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.modulate = Color(1.0, 0.4, 0.2, 0.9)
		lbl.visible = false
		add_child(lbl)
		indicator_pool.append(lbl)

func _process(_delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var vp_size = get_viewport_rect().size
	var ind_idx = 0
	
	for enemy in enemies:
		if ind_idx >= max_indicators:
			break
		if not is_instance_valid(enemy) or enemy.is_in_group("totems") or not enemy.has_method("is_alive") or not enemy.is_alive():
			continue
			
		var enemy_pos = enemy.global_position
		# Projeta na tela
		if not camera.is_position_behind(enemy_pos):
			var screen_pos = camera.unproject_position(enemy_pos)
			if screen_pos.x < 0 or screen_pos.x > vp_size.x or screen_pos.y < 0 or screen_pos.y > vp_size.y:
				# Fora da tela! Mostra indicador fixado na borda
				var clamped_pos = Vector2(
					clampf(screen_pos.x, margin, vp_size.x - margin),
					clampf(screen_pos.y, margin, vp_size.y - margin)
				)
				var ind = indicator_pool[ind_idx]
				ind.global_position = clamped_pos - (ind.size * 0.5)
				ind.visible = true
				
				# Rotação da seta apontando para a origem
				var center = vp_size * 0.5
				var dir = (screen_pos - center).normalized()
				ind.rotation = dir.angle()
				ind_idx += 1
		else:
			# Atrás da câmera
			var screen_pos = camera.unproject_position(-enemy_pos)
			var clamped_pos = Vector2(
				clampf(screen_pos.x, margin, vp_size.x - margin),
				clampf(screen_pos.y, margin, vp_size.y - margin)
			)
			var ind = indicator_pool[ind_idx]
			ind.global_position = clamped_pos - (ind.size * 0.5)
			ind.visible = true
			ind_idx += 1
			
	# Esconde indicadores excedentes
	while ind_idx < max_indicators:
		indicator_pool[ind_idx].visible = false
		ind_idx += 1

