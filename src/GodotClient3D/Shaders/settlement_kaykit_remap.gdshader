shader_type spatial;
render_mode diffuse_burley, specular_disabled;

// The Director: GFX-O. Keep KayKit Hexagon meshes. Remap the green
// atlas so roofs stay muted teal / terracotta and walls read as light
// limestone. At least half the wall area must stay pale stone.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 wall_color : source_color = vec4(0.812, 0.761, 0.651, 1.0); // #CFC2A6
uniform vec4 plaster_color : source_color = vec4(0.878, 0.816, 0.698, 1.0); // #E0D0B2
uniform vec4 masonry_color : source_color = vec4(0.518, 0.486, 0.420, 1.0); // #847C6B
uniform vec4 timber_color : source_color = vec4(0.380, 0.267, 0.184, 1.0); // #61442F
uniform vec4 roof_color : source_color = vec4(0.275, 0.424, 0.412, 1.0); // #466C69
uniform vec4 roof_shadow : source_color = vec4(0.188, 0.298, 0.286, 1.0); // #304C49
uniform vec4 terracotta : source_color = vec4(0.663, 0.388, 0.263, 1.0); // #A96343
uniform float use_terracotta = 0.0;
uniform float wall_lift = 1.32;
uniform float roughness = 0.88;

void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	float luma = dot(tex, vec3(0.2126, 0.7152, 0.0722));
	float mx = max(tex.r, max(tex.g, tex.b));
	float mn = min(tex.r, min(tex.g, tex.b));
	float sat = mx > 0.001 ? (mx - mn) / mx : 0.0;
	bool green = tex.g > tex.r + 0.035 && tex.g > tex.b + 0.015 && sat > 0.16;
	bool brown = tex.r > tex.g + 0.02 && tex.r > tex.b && sat > 0.14 && luma < 0.58;
	bool dark = luma < 0.30;
	vec3 roof_hi = mix(roof_color.rgb, terracotta.rgb, clamp(use_terracotta, 0.0, 1.0));
	vec3 roof = mix(roof_shadow.rgb, roof_hi, clamp(luma * 1.45, 0.18, 1.0));
	vec3 wall = mix(masonry_color.rgb, wall_color.rgb, smoothstep(0.22, 0.52, luma));
	wall = mix(wall, plaster_color.rgb, smoothstep(0.58, 0.86, luma));
	wall *= mix(0.96, 1.20, luma) * wall_lift;
	vec3 timber = timber_color.rgb * mix(0.88, 1.12, luma);
	vec3 albedo;
	if (green) {
		albedo = roof;
	} else if (brown && luma < 0.46) {
		albedo = timber;
	} else if (dark && sat < 0.28) {
		albedo = wall * 0.90;
	} else {
		albedo = wall;
	}
	ALBEDO = albedo;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.04;
}
