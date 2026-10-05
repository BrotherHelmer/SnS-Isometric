shader_type spatial;
render_mode unshaded, blend_mul, cull_disabled, depth_draw_opaque, shadows_disabled;

// The Director: GFX-04 contact darkening. One cheap disc under a building,
// tree or prop so objects occupy the ground instead of floating on it.
// blend_mul darkens whatever is already there — no extra lights.
uniform float intensity = 0.40;
uniform float inner = 0.16;
uniform float outer = 0.96;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	if (r > outer) {
		discard;
	}
	// Darkest in a ring at the object's feet, softer toward the centre and rim.
	float rim = 1.0 - smoothstep(outer - 0.18, outer, r);
	float contact = mix(0.78, 0.42, smoothstep(inner, 0.62, r));
	float shade = mix(1.0, contact, clamp(intensity, 0.0, 0.85) * rim);
	ALBEDO = vec3(shade);
	ALPHA = rim;
}
