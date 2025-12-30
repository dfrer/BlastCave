shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_count : hint_range(0, 1080) = 540.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.05;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float aberration : hint_range(0.0, 0.1) = 0.002;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Chromatic Aberration
	float r = texture(screen_texture, uv + vec2(aberration, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(aberration, 0.0)).b;
	vec3 color = vec3(r, g, b);
	
	// Scanlines
	float s = sin(uv.y * scanline_count * PI);
	s = (s * 0.5 + 0.5);
	color = mix(color, color * s, scanline_opacity);
	
	// Vignette
	float d = distance(uv, vec2(0.5, 0.5));
	float v = smoothstep(0.8, 1.5 - vignette_intensity, d);
	color = mix(color, color * v, vignette_opacity);
	
	COLOR = vec4(color, 1.0);
}
