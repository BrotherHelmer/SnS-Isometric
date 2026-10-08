shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

// The Director: GFX-08 foliage kit. Shared MultiMesh material. Wind only
// on the upper vertices so trunks stay planted.
uniform vec3 albedo_color : source_color = vec3(0.15, 0.22, 0.18);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float has_texture = 0.0;
uniform float wind = 0.07;
uniform float atmosphere = 1.0;

void vertex() {
	float h = VERTEX.y;
	float gust = sin(TIME * 0.65 + NODE_POSITION_WORLD.x * 0.13 + NODE_POSITION_WORLD.z * 0.09);
	float w = gust * wind * smoothstep(0.45, 1.8, h);
	VERTEX.x += w;
	VERTEX.z += w * 0.55;
}

void fragment() {
	vec3 tex = has_texture > 0.5 ? texture(albedo_tex, UV).rgb : vec3(1.0);
	ALBEDO = tex * albedo_color * atmosphere;
	ROUGHNESS = 0.90;
}
