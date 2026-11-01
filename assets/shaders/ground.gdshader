shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// ground.gdshader - Chão estilizado do diorama (grama ou terra batida)
// Mistura duas cores com ruído procedural em coordenadas de mundo,
// criando manchas suaves e "tufos" sem precisar de textura externa.

uniform vec4 color_a : source_color = vec4(0.47, 0.71, 0.30, 1.0);
uniform vec4 color_b : source_color = vec4(0.38, 0.62, 0.25, 1.0);
uniform vec4 speck_color : source_color = vec4(0.58, 0.80, 0.36, 1.0);
uniform float noise_scale = 0.18;
uniform float speck_amount = 0.12;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
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
	float n = noise(p * noise_scale) * 0.65 + noise(p * noise_scale * 2.7) * 0.35;
	vec3 col = mix(color_a.rgb, color_b.rgb, smoothstep(0.35, 0.75, n));
	// Pontinhos claros (flores/pedrinhas) espalhados
	float s = step(1.0 - speck_amount, hash(floor(p * 3.0)));
	col = mix(col, speck_color.rgb, s * 0.55);
	ALBEDO = col;
	ROUGHNESS = 0.95;
}

