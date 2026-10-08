shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

// The Director: GFX-C foliage. MultiMesh wind on the crown only.
// Height splits brown trunks from living canopy so the kit is not one
// dark blob from the strategy camera.
uniform vec3 albedo_color : source_color = vec3(0.24, 0.42, 0.22);
uniform vec3 trunk_color : source_color = vec3(0.32, 0.22, 0.16);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float has_texture = 0.0;
uniform float wind = 0.07;
uniform float atmosphere = 1.0;
uniform float canopy_lift = 1.45;

varying float world_h;

void vertex() {
	world_h = VERTEX.y;
	float h = VERTEX.y;
	float gust = sin(TIME * 0.65 + NODE_POSITION_WORLD.x * 0.13 + NODE_POSITION_WORLD.z * 0.09);
	float w = gust * wind * smoothstep(0.45, 1.8, h);
	VERTEX.x += w;
	VERTEX.z += w * 0.55;
}

void fragment() {
	vec3 tex = has_texture > 0.5 ? texture(albedo_tex, UV).rgb : vec3(1.0);
	float canopy = smoothstep(0.55, 1.55, world_h);
	vec3 leaf = albedo_color * canopy_lift;
	vec3 shade = mix(trunk_color, leaf, canopy);
	ALBEDO = tex * shade * atmosphere;
	ROUGHNESS = mix(0.86, 0.92, canopy);
}
