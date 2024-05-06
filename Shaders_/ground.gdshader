shader_type spatial;

uniform sampler2D noise_tex;

void vertex() {
	vec3 noise = texture(noise_tex, UV).xyz;
	VERTEX.y = noise.x * 10.0;
}

void fragment() {
	vec3 noise = texture(noise_tex, UV).xyz;
	ALBEDO = noise * vec3(0.1, 0.5, 0.6);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
