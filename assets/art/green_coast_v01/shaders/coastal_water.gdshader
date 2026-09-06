shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 deep_color : source_color = vec3(0.07, 0.25, 0.34);
uniform vec3 surface_color : source_color = vec3(0.14, 0.42, 0.52);
uniform vec3 crest_color : source_color = vec3(0.42, 0.66, 0.68);

void vertex() {
	float wave_a = sin(VERTEX.x * 0.24 + TIME * 0.48);
	float wave_b = cos(VERTEX.z * 0.29 + TIME * 0.36);
	VERTEX.y += (wave_a + wave_b) * 0.065;
}

void fragment() {
	float broad = 0.5 + 0.5 * sin(UV.x * 31.4159 + UV.y * 8.0 + TIME * 0.42);
	float crossing = 0.5 + 0.5 * cos(UV.y * 25.1327 - TIME * 0.30);
	float water_value = clamp(0.46 + broad * 0.10 + crossing * 0.06, 0.0, 1.0);
	float crest = smoothstep(0.82, 1.0, broad * 0.65 + crossing * 0.35);
	ALBEDO = mix(deep_color, surface_color, water_value);
	ALBEDO = mix(ALBEDO, crest_color, crest * 0.16);
	ROUGHNESS = 0.76;
	SPECULAR = 0.28;
}
