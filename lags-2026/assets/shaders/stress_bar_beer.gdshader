shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float wobble_x = sin(uv.y * 60.0 + time_sec * 7.0) * 0.006 * intensity;
	float wobble_y = sin(uv.x * 80.0 - time_sec * 5.0) * 0.003 * intensity;
	uv += vec2(wobble_x, wobble_y);
	COLOR = textureLod(screen_texture, uv, 0.0);
}
