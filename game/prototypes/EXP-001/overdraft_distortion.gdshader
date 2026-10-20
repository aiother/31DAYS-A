shader_type canvas_item;
// EXP-001: screen distortion while possibility is overdrawn (balance below 0).
// Drawn under the HUD so only the game scene is distorted.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float wave = sin(uv.y * 38.0 + TIME * 3.1) + sin(uv.y * 91.0 - TIME * 5.3) * 0.5;
	uv.x += wave * 0.0035 * strength;
	float split = 0.007 * strength;
	vec3 color;
	color.r = texture(screen_texture, uv + vec2(split, 0.0)).r;
	color.g = texture(screen_texture, uv).g;
	color.b = texture(screen_texture, uv - vec2(split, 0.0)).b;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(grey) * vec3(0.92, 0.86, 1.0), 0.55 * strength);
	float edge = smoothstep(0.35, 0.95, length(SCREEN_UV - vec2(0.5)) * 1.4);
	color *= 1.0 - edge * 0.45 * strength;
	COLOR = vec4(color, 1.0);
}
