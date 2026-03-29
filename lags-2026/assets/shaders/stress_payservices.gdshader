shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float wave1 = sin(uv.y * 55.0 + time_sec * 3.5);
	float wave2 = sin(uv.y * 110.0 - time_sec * 2.0);
	uv.x += (wave1 * 0.008 + wave2 * 0.004) * intensity;
	uv.y += sin(uv.x * 90.0 + time_sec * 2.7) * 0.003 * intensity;
	vec4 col = textureLod(screen_texture, uv, 0.0);
	col.rgb *= 1.0 + 0.06 * intensity;
	COLOR = vec4(clamp(col.rgb, 0.0, 1.0), 1.0);
}
