shader_type spatial;
render_mode cull_front, unshaded;

// outline_inverted_hull.gdshader - Contorno nítido por extrusão normal (Inverted Hull)
// Extremamente leve em GPU mobile (sem passes pós-processamento na tela)

uniform vec4 outline_color : source_color = vec4(0.169, 0.106, 0.071, 1.0); // #2B1B12 (marrom escuro estilizado)
uniform float outline_width : hint_range(0.0, 0.06) = 0.022;

void vertex() {
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}

