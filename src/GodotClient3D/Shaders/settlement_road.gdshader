shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
uniform vec4 road_color : source_color = vec4(0.4, 0.3, 0.2, 1.0);
uniform vec3 light_tint : source_color = vec3(1.0);
void fragment() {
	ALBEDO = road_color.rgb * light_tint;
	ALPHA = road_color.a;
}
