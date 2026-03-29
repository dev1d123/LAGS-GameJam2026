shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_sec = 0.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float wave_a = sin((uv.y * 82.0) + time_sec * 4.2);
	float wave_b = sin((uv.x * 69.0) - time_sec * 3.5);
	uv += vec2(wave_a * 0.006, wave_b * 0.0045) * intensity;

	float pixel_steps = mix(540.0, 140.0, clamp(intensity / 2.0, 0.0, 1.0));
	vec2 pix_uv = floor(uv * pixel_steps) / pixel_steps;

	float aberr = 0.0065 * intensity;
	float r = textureLod(screen_texture, pix_uv + vec2(aberr, 0.0), 0.0).r;
	float g = textureLod(screen_texture, pix_uv, 0.0).g;
	float b = textureLod(screen_texture, pix_uv - vec2(aberr, 0.0), 0.0).b;
	vec3 rgb = vec3(r, g, b);

	vec3 hsv = rgb2hsv(rgb);
	float drift = (sin((uv.x + uv.y) * 23.0 + time_sec * 2.6) * 0.5 + 0.5) * 0.16 * intensity;
	hsv.x = fract(hsv.x + drift);
	hsv.y = clamp(hsv.y * (1.0 + 0.55 * intensity), 0.0, 1.0);
	hsv.z = clamp(hsv.z * (1.0 + 0.18 * intensity), 0.0, 1.0);

	rgb = hsv2rgb(hsv);
	float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
	rgb += smoothstep(0.55, 1.0, luma) * 0.28 * intensity;

	COLOR = vec4(clamp(rgb, 0.0, 1.0), 1.0);
}
