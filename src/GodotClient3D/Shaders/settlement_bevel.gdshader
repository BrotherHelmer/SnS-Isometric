shader_type spatial;
render_mode blend_add, cull_back, diffuse_lambert, specular_disabled;

// The Director: GFX-07 fake bevel. A thin fresnel catch-light stands in
// for 1–2% mesh bevels so roof/timber/plaster edges read from the
// strategy camera without a remodel.
uniform vec3 bevel_color : source_color = vec3(1.0, 0.90, 0.72);
uniform float bevel_amount = 0.14;

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.8);
	ALBEDO = vec3(0.0);
	EMISSION = bevel_color * fres * bevel_amount;
}
