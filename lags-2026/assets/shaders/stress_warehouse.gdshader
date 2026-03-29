shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 col = textureLod(screen_texture, uv, 0.0);
	float flicker = 1.0 - (0.18 * intensity) + (sin(time_sec * 14.0) * 0.08 * intensity);
	float noise = hash(floor(uv * vec2(640.0, 360.0) + time_sec * 25.0));
	col.rgb *= flicker;
	col.rgb += (noise - 0.5) * 0.18 * intensity;
	col.rgb = pow(clamp(col.rgb, 0.0, 1.0), vec3(1.0 + 0.35 * intensity));
	COLOR = vec4(clamp(col.rgb, 0.0, 1.0), col.a);
}
