shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE * (1.0 + 3.2 * intensity);

	vec4 c = textureLod(screen_texture, uv, 0.0) * 0.22;
	c += textureLod(screen_texture, uv + vec2(px.x, 0.0), 0.0) * 0.13;
	c += textureLod(screen_texture, uv - vec2(px.x, 0.0), 0.0) * 0.13;
	c += textureLod(screen_texture, uv + vec2(0.0, px.y), 0.0) * 0.13;
	c += textureLod(screen_texture, uv - vec2(0.0, px.y), 0.0) * 0.13;
	c += textureLod(screen_texture, uv + px, 0.0) * 0.09;
	c += textureLod(screen_texture, uv - px, 0.0) * 0.09;
	c += textureLod(screen_texture, uv + vec2(px.x, -px.y), 0.0) * 0.04;
	c += textureLod(screen_texture, uv + vec2(-px.x, px.y), 0.0) * 0.04;

	float darken = 1.0 - 0.08 * intensity;
	COLOR = vec4(clamp(c.rgb * darken, 0.0, 1.0), 1.0);
}
