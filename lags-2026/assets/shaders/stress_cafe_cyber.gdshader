shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float aberr = 0.0075 * intensity;
	float jitter = sin(uv.y * 360.0 + time_sec * 42.0) * 0.0024 * intensity;
	uv.x += jitter;

	float r = textureLod(screen_texture, uv + vec2(aberr, 0.0), 0.0).r;
	float g = textureLod(screen_texture, uv, 0.0).g;
	float b = textureLod(screen_texture, uv - vec2(aberr, 0.0), 0.0).b;

	vec3 rgb = vec3(r, g, b);
	float scan = sin((uv.y + time_sec * 0.6) * 980.0) * 0.5 + 0.5;
	rgb *= 1.0 - (0.32 * intensity * scan);
	COLOR = vec4(clamp(rgb, 0.0, 1.0), 1.0);
}
