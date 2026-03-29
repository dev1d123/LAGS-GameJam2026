shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float smear = 0.018 * intensity;
	vec4 c0 = textureLod(screen_texture, uv, 0.0);
	vec4 c1 = textureLod(screen_texture, uv + vec2(0.0, smear), 0.0);
	vec4 c2 = textureLod(screen_texture, uv + vec2(0.0, smear * 2.0), 0.0);
	vec4 col = (c0 * 0.6) + (c1 * 0.25) + (c2 * 0.15);

	float flash = (sin(time_sec * 11.0) * 0.5 + 0.5) * 0.28 * intensity;
	col.rgb = mix(col.rgb, vec3(col.r + flash, col.g * (1.0 - flash * 0.4), col.b * (1.0 - flash * 0.5)), 0.45 * intensity);
	COLOR = vec4(clamp(col.rgb, 0.0, 1.0), col.a);
}
