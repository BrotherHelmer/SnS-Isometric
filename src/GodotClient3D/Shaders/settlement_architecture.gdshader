shader_type spatial;
render_mode diffuse_burley, specular_disabled;

// The Director: GFX-Q civic architecture. Real 1K CC0 maps supply
// luminance-or-detail only. Palettes stay the GFX-P limestone /
// plaster / timber / teal-slate. Never invent masonry from the
// green Hexagon atlas. No early return — Godot rejects it.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.804, 0.749, 0.635, 1.0); // #CDBFA2
uniform float tex_mix = 0.42;
uniform float roughness = 0.90;
uniform float uv_scale = 2.6;
uniform float luma_lift = 0.92;
uniform float emission_amt = 0.02;

void fragment() {
	vec3 tex = texture(albedo_tex, UV * uv_scale).rgb;
	float luma = dot(tex, vec3(0.2126, 0.7152, 0.0722));
	vec3 detail = mix(vec3(1.0), tex / max(luma, 0.10), clamp(tex_mix, 0.0, 0.55));
	float lift = mix(0.94, 1.14, clamp(luma * luma_lift, 0.0, 1.0));
	vec3 albedo = tint.rgb * detail * lift;
	ALBEDO = albedo;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.04;
	EMISSION = albedo * emission_amt;
}
