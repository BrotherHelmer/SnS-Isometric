shader_type canvas_item;

// The dynamic viewport texture painted by FogManager.
uniform sampler2D fog_mask : hint_default_white;
// Base colour of the Wyrd Fog — deep ominous purple.
uniform vec4 fog_color : source_color = vec4(0.15, 0.05, 0.2, 0.92);

void fragment() {
	float mask_value = texture(fog_mask, UV).r;
	// mask_value == 1.0 → full fog (white = untouched)
	// mask_value == 0.0 → fully cleared by a lumen source
	COLOR = vec4(fog_color.rgb, fog_color.a * mask_value);
}
