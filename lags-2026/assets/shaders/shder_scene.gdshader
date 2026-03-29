shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// --- PARÁMETROS ---
uniform float saturation_amount : hint_range(0.0, 1.0) = 1.0;
uniform float blur_intensity : hint_range(0.0, 5.0) = 0.0;
uniform float stress_tunnel : hint_range(0.0, 1.0) = 0.0;

uniform vec2 player_screen_uv = vec2(0.5, 0.5); 

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = texture(screen_texture, uv);

    // EFECTO ENERGIA BLUR
    if (blur_intensity > 0.3) {
        float samples = 8.0;
        vec4 blur_color = color;
        float pulse = sin(TIME * 2.0) * 0.5 + 0.5;
        float radius = blur_intensity * pulse * SCREEN_PIXEL_SIZE.x * 2.0;
        
        for (float i = 1.0; i <= samples; i++) {
            float angle = i * (6.28318 / samples);
            vec2 offset = vec2(cos(angle), sin(angle)) * radius;
            blur_color += texture(screen_texture, uv + offset);
        }
        color = blur_color / (samples + 1.0);
    }

    float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(vec3(luminance), color.rgb, saturation_amount);

    // Stress tunel
    if (stress_tunnel >= 0.0) {
        vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
        float dist = distance(uv * aspect, player_screen_uv * aspect);
        
        float outer_edge = 1.2 - (stress_tunnel * 0.8);
        float inner_edge = 0.5 - (stress_tunnel * 0.4);
        
        float vignette = smoothstep(outer_edge, inner_edge, dist);
        color.rgb *= vignette;
    }

    COLOR = color;
}