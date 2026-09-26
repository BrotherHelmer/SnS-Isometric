shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D palette_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool has_texture = false;
void fragment() {
	vec3 c = base_color.rgb;
	if (has_texture) { c *= texture(palette_texture, UV).rgb; }
	float luminance = dot(c, vec3(0.2126, 0.7152, 0.0722));
	// Remap vivid green/cyan cloth while preserving skin, leather and steel.
	float cloth = smoothstep(0.02, 0.16, c.g - max(c.r, c.b * 0.8));
	vec3 pine = vec3(0.055, 0.12, 0.09) * (0.65 + luminance * 1.8);
	ALBEDO = mix(mix(vec3(luminance), c, 0.78), pine, cloth * 0.90);
	ROUGHNESS = 0.87;
	SPECULAR = 0.22;
}
