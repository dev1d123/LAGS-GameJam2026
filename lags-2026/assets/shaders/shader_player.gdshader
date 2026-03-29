shader_type canvas_item;

uniform float malaise_amount : hint_range(0.0, 1.0) = 0.0;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    float aberration_amount = 0.0;

    // ABERRACIÓN 
    if (malaise_amount > 0.5) {
        float intensity = (malaise_amount - 0.5) * 2.0; 
        aberration_amount = intensity * 0.006;
        
        // Pulso de aberración muy suave
        float soft_pulse = sin(TIME * 1.5) * 0.5 + 0.5;
        aberration_amount += (0.001 * soft_pulse);
    }

    if (malaise_amount > 0.9) {
        float shake_trigger = hash(floor(TIME * 3.0)); // Frecuencia muy baja
        if (shake_trigger > 0.7) {
            uv.x += (hash(TIME) - 0.5) * 0.003 * malaise_amount; 
        }
    }

    // GLITCH FINAL CALMADO
    if (malaise_amount > 0.98) {
        float slice = floor(uv.y * 12.0); // Franjas más gruesas
        float glitch_trigger = hash(slice + floor(TIME * 3.0)); // Movimiento lento
        
        if (glitch_trigger > 0.9) {
            uv.x += (hash(slice + TIME) - 0.5) * 0.03; 
        }
    }

    vec4 sampled_color;
    if (aberration_amount > 0.0) {
        float r = texture(TEXTURE, uv + vec2(aberration_amount, 0.0)).r;
        float g = texture(TEXTURE, uv).g;
        float b = texture(TEXTURE, uv - vec2(aberration_amount, 0.0)).b;
        sampled_color = vec4(r, g, b, texture(TEXTURE, uv).a);
    } else {
        sampled_color = texture(TEXTURE, uv);
    }

    // CAMBIO DE COLOR 
    if (malaise_amount > 0.98) {
        float heartbeat = sin(TIME * 3.0) * 0.5 + 0.5;
        float red_glow = pow(heartbeat, 2.0);

        vec3 warning_red = vec3(0.8, 0.0, 0.1);
        
        sampled_color.rgb = mix(sampled_color.rgb, warning_red, red_glow * 0.6);
    }

    COLOR = sampled_color;
}