shader_type spatial;
render_mode diffuse_toon, specular_disabled;

// ground.gdshader - Terreno estilizado Toon para Diorama Mobile
// Cores limpas e suaves inspiradas em Kingshot e Clash of Clans:
// Grama rica com transição suave para terra batida/areia sem ruído pixelado

uniform vec4 grass_main : source_color = vec4(0.525, 0.761, 0.196, 1.0); // #86C232
uniform vec4 grass_shade : source_color = vec4(0.435, 0.659, 0.169, 1.0); // #6FA82B
uniform vec4 dirt_path : source_color = vec4(0.851, 0.627, 0.400, 1.0);  // #D9A066
uniform float path_weight : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale : hint_range(0.01, 1.0) = 0.09;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	// Ruído suave em duas oitavas suaves
	float n = smooth_noise(p * noise_scale) * 0.65 + smooth_noise(p * (noise_scale * 2.2)) * 0.35;
	vec3 grass = mix(grass_main.rgb, grass_shade.rgb, smoothstep(0.35, 0.68, n));
	vec3 final_color = mix(grass, dirt_path.rgb, path_weight);
	
	ALBEDO = final_color;
	ROUGHNESS = 0.88;
}
