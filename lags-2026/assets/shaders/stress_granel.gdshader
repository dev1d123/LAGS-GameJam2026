shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float n = fract(sin(dot(floor(uv * 900.0), vec2(12.9898, 78.233))) * 43758.5453 + time_sec * 12.0);
	vec2 jitter = (vec2(n, 1.0 - n) - 0.5) * 0.0035 * intensity;
	vec4 base = textureLod(screen_texture, uv + jitter, 0.0);
	vec4 ghost = textureLod(screen_texture, uv + vec2(0.0025 * intensity, 0.0), 0.0);
	base.rgb = mix(base.rgb, ghost.rgb, 0.22 * intensity);
	COLOR = base;
}
