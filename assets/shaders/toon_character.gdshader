shader_type spatial;
render_mode diffuse_toon, specular_toon;

// toon_character.gdshader - Toon Shading limpo com 2 faixas de luz e rim light suave
// Desenvolvido para máxima legibilidade mobile (estilo Kingshot / Clash of Clans)

uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 shade_color : source_color = vec4(0.3, 0.3, 0.35, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_texture = false;
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.65;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 0.3);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.7;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

void fragment() {
	vec3 texture_color = texture(albedo_texture, UV).rgb;
	ALBEDO = use_albedo_texture ? pow(texture_color, vec3(0.78)) : base_color.rgb;
	ROUGHNESS = roughness_val;
	METALLIC = metallic_val;
	if (emission_energy > 0.0) {
		EMISSION = emission_color.rgb * emission_energy;
	}
}

void light() {
	float n_dot_l = dot(NORMAL, LIGHT);
	// Faixa toon limpa com transição rápida
	float light_step = smoothstep(0.05, 0.18, n_dot_l);
	vec3 diffuse = mix(shade_color.rgb * ALBEDO, ALBEDO, light_step);
	
	// Rim light suave nas silhuetas
	float rim = 1.0 - max(dot(VIEW, NORMAL), 0.0);
	float rim_term = smoothstep(rim_threshold, 1.0, rim) * max(n_dot_l, 0.0);
	
	DIFFUSE_LIGHT += diffuse * LIGHT_COLOR * ATTENUATION + (rim_color.rgb * rim_term * rim_color.a);
}

