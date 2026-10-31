shader_type canvas_item;

// retro_crt.gdshader - Shader do Modo Retrô do Reino Pequenino
// Adiciona leve pixelização, scanlines sutis e calor cromático estilo tela antiga de tubo / fliperama

uniform float scanline_density : hint_range(100.0, 800.0) = 360.0;
uniform float scanline_intensity : hint_range(0.0, 0.4) = 0.12;
uniform float pixel_downsample : hint_range(1.0, 6.0) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Pixelização opcional se pixel_downsample > 1.0
    if (pixel_downsample > 1.0) {
        vec2 grid = vec2(textureSize(screen_texture, 0)) / pixel_downsample;
        uv = floor(uv * grid) / grid;
    }
    
    // Separação cromática sutil nas bordas
    float r = texture(screen_texture, uv + vec2(0.001, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(0.001, 0.0)).b;
    vec3 color = vec3(r, g, b);
    
    // Scanlines horizontais suaves
    float scanline = sin(uv.y * scanline_density * 3.14159) * 0.5 + 0.5;
    color -= scanline * scanline_intensity;
    
    // Leve aquecimento nostálgico
    color *= vec3(1.02, 1.0, 0.96);
    
    COLOR = vec4(color, 1.0);
}

