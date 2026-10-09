shader_type spatial;
render_mode diffuse_burley, specular_disabled;

// The Director: GFX-P. Civic walls IGNORE the green Hexagon atlas RGB.
// A bright albedo_color cannot lift a dark imported texture. Emit
// limestone / plaster / recess from the world normal only so at least
// half the wall area reads pale on the gameplay camera.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 wall_color : source_color = vec4(0.804, 0.749, 0.635, 1.0); // #CDBFA2
uniform vec4 plaster_color : source_color = vec4(0.878, 0.816, 0.698, 1.0); // #E0D0B2
uniform vec4 masonry_color : source_color = vec4(0.510, 0.475, 0.416, 1.0); // #82796A
uniform vec4 timber_color : source_color = vec4(0.373, 0.267, 0.184, 1.0); // #5F442F
uniform vec4 roof_color : source_color = vec4(0.271, 0.420, 0.408, 1.0); // #456B68
uniform vec4 roof_shadow : source_color = vec4(0.188, 0.298, 0.286, 1.0); // #304C49
uniform vec4 terracotta : source_color = vec4(0.663, 0.388, 0.263, 1.0); // #A96343
uniform float use_terracotta = 0.0;
uniform float wall_lift = 1.22;
uniform float roughness = 0.90;

void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	float luma = dot(tex, vec3(0.2126, 0.7152, 0.0722));
	float mx = max(tex.r, max(tex.g, tex.b));
	float mn = min(tex.r, min(tex.g, tex.b));
	float sat = mx > 0.001 ? (mx - mn) / mx : 0.0;
	vec3 world_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	bool roof_face = world_n.y > 0.46;
	bool green = tex.g > tex.r + 0.035 && tex.g > tex.b + 0.015 && sat > 0.16;
	bool brown = tex.r > tex.g + 0.02 && tex.r > tex.b && sat > 0.14 && luma < 0.58;
	bool dark = luma < 0.30;
	vec3 roof_hi = mix(roof_color.rgb, terracotta.rgb, clamp(use_terracotta, 0.0, 1.0));
	vec3 roof = mix(roof_shadow.rgb, roof_hi, clamp(luma * 1.45, 0.18, 1.0));
	vec3 albedo;
	EMISSION = vec3(0.0);
	if (use_terracotta < 0.5) {
		// Civic: atlas RGB/luma do not decide the wall. Roof only on
		// clearly upward faces (y > 0.70). Everything else is pale
		// limestone / plaster so ≥50% of the wall reads light on camera.
		float roof_w = smoothstep(0.70, 0.86, world_n.y);
		float cam_face = smoothstep(-0.20, 0.55, world_n.z);
		vec3 wall = mix(wall_color.rgb, plaster_color.rgb, 0.58 + cam_face * 0.32);
		wall = mix(wall, masonry_color.rgb, 0.08 * (1.0 - cam_face));
		wall *= wall_lift;
		albedo = mix(wall, roof, roof_w);
		if (brown && luma < 0.34 && sat > 0.28 && roof_w < 0.20) {
			albedo = timber_color.rgb * mix(0.92, 1.08, luma);
		}
		EMISSION = mix(wall * 0.10, vec3(0.0), roof_w);
	} else {
		vec3 wall = mix(wall_color.rgb, plaster_color.rgb, smoothstep(0.40, 0.82, luma));
		wall = mix(masonry_color.rgb, wall, smoothstep(0.16, 0.38, luma));
		wall *= mix(1.04, 1.18, luma) * wall_lift;
		vec3 timber = timber_color.rgb * mix(0.88, 1.12, luma);
		if (green && roof_face) {
			albedo = roof;
		} else if (brown && luma < 0.46) {
			albedo = timber;
		} else if (dark && sat < 0.28) {
			albedo = wall * 0.90;
		} else {
			albedo = wall;
		}
	}
	ALBEDO = albedo;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.04;
}
