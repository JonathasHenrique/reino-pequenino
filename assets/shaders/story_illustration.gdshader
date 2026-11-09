shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 4.0) = 1.7;
uniform float palette_mix : hint_range(0.0, 1.0) = 0.30;
uniform vec4 palette_top : source_color = vec4(0.10, 0.18, 0.40, 1.0);
uniform vec4 palette_bottom : source_color = vec4(0.92, 0.65, 0.34, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float saturation : hint_range(0.0, 1.5) = 0.92;

void fragment() {
	vec2 px = vec2(blur_amount) / vec2(1280.0, 720.0);
	vec4 c = texture(TEXTURE, UV) * 0.2270270270;
	c += texture(TEXTURE, UV + vec2(px.x, 0.0)) * 0.1295405405;
	c += texture(TEXTURE, UV - vec2(px.x, 0.0)) * 0.1295405405;
	c += texture(TEXTURE, UV + vec2(0.0, px.y)) * 0.1295405405;
	c += texture(TEXTURE, UV - vec2(0.0, px.y)) * 0.1295405405;
	c += texture(TEXTURE, UV + px) * 0.0739509509;
	c += texture(TEXTURE, UV - px) * 0.0739509509;
	c += texture(TEXTURE, UV + vec2(px.x, -px.y)) * 0.0739509509;
	c += texture(TEXTURE, UV + vec2(-px.x, px.y)) * 0.0739509509;

	vec3 palette = mix(palette_top.rgb, palette_bottom.rgb, UV.y);
	vec3 col = mix(c.rgb, palette, palette_mix);
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, saturation);

	vec2 d = UV - vec2(0.5);
	float v = 1.0 - dot(d, d) * vignette_strength * 2.2;
	col *= clamp(v, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
