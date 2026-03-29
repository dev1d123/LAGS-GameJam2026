shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float wobble_x = sin(uv.y * 70.0 + time_sec * 7.5) * 0.018 * intensity;
	float wobble_y = sin(uv.x * 95.0 - time_sec * 5.5) * 0.010 * intensity;
	uv += vec2(wobble_x, wobble_y);
	float aberr = 0.004 * intensity;
	float r = textureLod(screen_texture, uv + vec2(aberr, 0.0), 0.0).r;
	float g = textureLod(screen_texture, uv, 0.0).g;
	float b = textureLod(screen_texture, uv - vec2(aberr, 0.0), 0.0).b;
	COLOR = vec4(clamp(vec3(r, g, b), 0.0, 1.0), 1.0);
}
