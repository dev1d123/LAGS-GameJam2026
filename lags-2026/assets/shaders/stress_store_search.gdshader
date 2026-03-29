shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);
	float dist = length(centered);
	float vignette = smoothstep(0.3, 0.75, dist);
	float lod = vignette * intensity * 2.8;
	vec4 col = textureLod(screen_texture, uv, lod);
	float pulse = sin(time_sec * 1.3 + dist * 18.0) * 0.02 * intensity;
	col.rgb *= 1.0 - (vignette * 0.25 * intensity) + pulse;
	COLOR = col;
}
