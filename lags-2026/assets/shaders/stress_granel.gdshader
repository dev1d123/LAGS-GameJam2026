shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 3.2) = 0.0;
uniform float time_sec = 0.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float power = clamp(intensity * 0.58, 0.0, 2.2);

	vec2 aberr = vec2(0.0008 * power, 0.0);
	float red = textureLod(screen_texture, uv + aberr, 0.0).r;
	float green = textureLod(screen_texture, uv, 0.0).g;
	float blue = textureLod(screen_texture, uv - aberr, 0.0).b;
	vec3 col = vec3(red, green, blue);

	float scan = sin((uv.y + time_sec * 0.9) * 900.0) * 0.04 * power;
	float noise = (hash12(vec2(floor(uv.x * 320.0), floor((uv.y + time_sec * 0.35) * 180.0))) - 0.5) * 0.10 * power;
	col += vec3(scan + noise);

	float vignette = smoothstep(0.92, 0.28, distance(uv, vec2(0.5)));
	col *= 1.0 - 0.17 * power * vignette;
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
