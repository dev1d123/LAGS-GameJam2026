shader_type canvas_item;

// --- GLOW (Resplandor por fuera) ---
uniform vec4 glow_color : source_color = vec4(1.0, 0.65, 0.3, 1.0);
uniform float glow_size : hint_range(0.0, 10.0) = 0.0;
uniform float glow_density : hint_range(0.0, 5.0) = 1.5;

// --- COLOR INTERIOR ---
// > 1.0 aumenta la saturación
uniform float saturation : hint_range(0.0, 5.0) = 1.0;

// NUEVO: Color para el tinte interior luminoso (ej. crema, amarillo suave).
uniform vec4 tint_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
// 1.0 es el brillo neutral. > 1.0 mezcla tu dibujo con el tinte de arriba.
uniform float brightness : hint_range(0.0, 5.0) = 1.0;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;
	vec4 col = texture(TEXTURE, UV);

	// 1. Calculamos el glow exterior
	float alpha = 0.0;
	if (glow_size > 0.0) {
		for (float i = 1.0; i <= 3.0; i++) {
			float dist = glow_size * (i / 3.0);
			alpha += texture(TEXTURE, UV + vec2(dist * ps.x, 0.0)).a;
			alpha += texture(TEXTURE, UV + vec2(-dist * ps.x, 0.0)).a;
			alpha += texture(TEXTURE, UV + vec2(0.0, dist * ps.y)).a;
			alpha += texture(TEXTURE, UV + vec2(0.0, -dist * ps.y)).a;
			alpha += texture(TEXTURE, UV + vec2(dist * ps.x, dist * ps.y)).a;
			alpha += texture(TEXTURE, UV + vec2(-dist * ps.x, dist * ps.y)).a;
			alpha += texture(TEXTURE, UV + vec2(dist * ps.x, -dist * ps.y)).a;
			alpha += texture(TEXTURE, UV + vec2(-dist * ps.x, -dist * ps.y)).a;
		}
		alpha /= 24.0;
	}

	// 2. Aplicamos la Lógica de Color Interior al dibujo original
	if (col.a > 0.0) {
		// Primero la saturación (colores más ricos)
		float luminance = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		vec3 grayscale = vec3(luminance);
		col.rgb = mix(grayscale, col.rgb, saturation);

		// Luego aplicamos el tinte luminoso (NUEVA FÓRMULA)
		// Usamos mix() para teñir, y multiplicamos el tinte para dar luz.
		// brillo=1.0 -> mix(0.0) -> color original.
		// brillo=1.3 -> mix(0.3) -> 70% color, 30% tinte brillante.
		float tint_factor = max(0.0, brightness - 1.0);
		vec3 bright_tint = tint_color.rgb * brightness;
		col.rgb = mix(col.rgb, bright_tint, tint_factor);
	}

	// 3. Dibujamos en pantalla
	if (col.a < 0.1 && alpha > 0.0) {
		COLOR = glow_color;
		COLOR.a = clamp(alpha * glow_density * 4.0, 0.0, 1.0) * glow_color.a;
	} else {
		COLOR = col;
	}
}