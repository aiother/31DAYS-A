shader_type canvas_item;
// EXP-003 variant C: blur, warm desaturation and slight lift over the
// stand-in game scene drawn beneath it.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float radius = 0.006;

void fragment() {
	vec3 sum = vec3(0.0);
	float total = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			vec2 offset = vec2(float(x), float(y)) * radius;
			float weight = 1.0 - length(vec2(float(x), float(y))) / 5.0;
			sum += textureLod(screen_texture, SCREEN_UV + offset, 2.0).rgb * weight;
			total += weight;
		}
	}
	vec3 color = sum / total;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(grey) * vec3(1.08, 0.94, 0.86), 0.4);
	COLOR = vec4(color * 0.92 + 0.04, 1.0);
}
