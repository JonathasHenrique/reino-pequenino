shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled;

// healthbar.gdshader - Barra de vida 3D sempre virada para a câmera.
// Um único material compartilhado; cada barra usa "instance uniforms"
// (ratio e cor), então não cria materiais novos por inimigo.

instance uniform float ratio = 1.0;
instance uniform vec4 fill_color : source_color = vec4(0.35, 0.85, 0.30, 1.0);

void vertex() {
	// Billboard: mantém a orientação da câmera, preservando a posição do nó
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = UV;
	float border_x = 0.035;
	float border_y = 0.22;
	bool is_border = uv.x < border_x || uv.x > 1.0 - border_x || uv.y < border_y || uv.y > 1.0 - border_y;
	vec3 col;
	if (is_border) {
		col = vec3(0.08, 0.06, 0.05);
	} else {
		float inner_x = (uv.x - border_x) / (1.0 - 2.0 * border_x);
		col = inner_x <= ratio ? fill_color.rgb : vec3(0.22, 0.16, 0.14);
		// brilho na metade de cima para dar volume
		if (uv.y < 0.5) {
			col *= 1.18;
		}
	}
	ALBEDO = col;
}

