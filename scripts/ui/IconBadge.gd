extends Control

# Ícones vetoriais simples e consistentes, sem depender de emojis do sistema.

@export_enum("coin", "helmet", "heart", "archer", "crown") var icon_type: String = "coin"
@export var icon_color: Color = Color("#FFC93C")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.35
	match icon_type:
		"coin":
			draw_circle(center, radius, icon_color)
			draw_arc(center, radius * 0.72, 0.0, TAU, 24, Color("#D99B26"), 2.0, true)
			draw_line(center + Vector2(0, -radius * 0.45), center + Vector2(0, radius * 0.45), Color("#FFF3D6"), 2.0, true)
		"helmet":
			var helmet := PackedVector2Array([
				center + Vector2(-radius, 2), center + Vector2(-radius * 0.82, -radius * 0.48),
				center + Vector2(-radius * 0.25, -radius * 0.95), center + Vector2(radius * 0.62, -radius * 0.62),
				center + Vector2(radius, 2), center + Vector2(radius * 0.72, radius * 0.45),
				center + Vector2(-radius * 0.72, radius * 0.45)
			])
			draw_colored_polygon(helmet, icon_color)
			draw_line(center + Vector2(-radius * 0.75, radius * 0.45), center + Vector2(radius * 0.75, radius * 0.45), Color("#2B1B12"), 2.0, true)
		"heart":
			var heart := PackedVector2Array([
				center + Vector2(0, radius), center + Vector2(-radius, -radius * 0.05),
				center + Vector2(-radius * 0.78, -radius * 0.75), center + Vector2(-radius * 0.28, -radius),
				center, center + Vector2(radius * 0.28, -radius), center + Vector2(radius * 0.78, -radius * 0.75),
				center + Vector2(radius, -radius * 0.05)
			])
			draw_colored_polygon(heart, Color("#D9363E"))
		"archer":
			draw_arc(center + Vector2(-2, 0), radius * 0.78, -PI * 0.5, PI * 0.5, 18, icon_color, 3.0, true)
			draw_line(center + Vector2(-2, -radius * 0.78), center + Vector2(-2, radius * 0.78), icon_color, 2.0, true)
			draw_line(center + Vector2(-2, 0), center + Vector2(radius, 0), Color("#FFF3D6"), 2.5, true)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(radius, 0), center + Vector2(radius * 0.55, -4), center + Vector2(radius * 0.55, 4)
			]), Color("#FFF3D6"))
		"crown":
			var crown := PackedVector2Array([
				center + Vector2(-radius, -radius * 0.55), center + Vector2(-radius * 0.45, radius * 0.1),
				center, center + Vector2(radius * 0.45, radius * 0.1), center + Vector2(radius, -radius * 0.55),
				center + Vector2(radius * 0.72, radius * 0.78), center + Vector2(-radius * 0.72, radius * 0.78)
			])
			draw_colored_polygon(crown, icon_color)
			draw_line(center + Vector2(-radius * 0.65, radius * 0.48), center + Vector2(radius * 0.65, radius * 0.48), Color("#D99B26"), 2.0, true)
