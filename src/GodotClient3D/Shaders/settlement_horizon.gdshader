shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;

// The Director: G1 distant hills. Unshaded so lavapipe does not
// light a far ring. Atmosphere scales with the period palette.
uniform vec3 albedo_color : source_color = vec3(0.22, 0.28, 0.24);
uniform float atmosphere = 1.0;

void fragment() {
	ALBEDO = albedo_color * mix(0.55, 1.0, atmosphere);
}
