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
	vec4 col = textureLod(screen_texture, uv, 0.0);
	vec3 hsv = rgb2hsv(col.rgb);

	float drift = (sin((uv.x + uv.y) * 20.0 + time_sec * 1.8) * 0.5 + 0.5) * 0.06 * intensity;
	hsv.x = fract(hsv.x + drift);
	hsv.y = clamp(hsv.y * (1.0 + 0.25 * intensity), 0.0, 1.0);

	vec3 rgb = hsv2rgb(hsv);
	float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
	rgb += smoothstep(0.6, 1.0, luma) * 0.15 * intensity;
	COLOR = vec4(clamp(rgb, 0.0, 1.0), col.a);
}
