shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D palette_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool has_texture = false;
uniform vec3 rim_color : source_color = vec3(0.92, 0.82, 0.62);
uniform float rim_amount = 0.16;

void fragment() {
	vec3 c = base_color.rgb;
	if (has_texture) { c *= texture(palette_texture, UV).rgb; }
	float luminance = dot(c, vec3(0.2126, 0.7152, 0.0722));
	// Remap vivid green/cyan cloth while preserving skin, leather and steel.
	float cloth = smoothstep(0.02, 0.16, c.g - max(c.r, c.b * 0.8));
	vec3 pine = vec3(0.10, 0.18, 0.13) * (0.70 + luminance * 1.7);
	vec3 shaded = mix(mix(vec3(luminance), c, 0.82), pine, cloth * 0.82);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	ALBEDO = mix(shaded, rim_color, fresnel * rim_amount);
	EMISSION = rim_color * fresnel * rim_amount * 0.42;
	ROUGHNESS = 0.84;
	SPECULAR = 0.24;
}
