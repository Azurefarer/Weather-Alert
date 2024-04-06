shader_type spatial;

void fragment() {
	ALBEDO = vec3(UV, UV.x);
}
