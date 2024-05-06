shader_type spatial;
render_mode skip_vertex_transform;

// Vignette
uniform sampler2D spotlight;
uniform vec4 vignette_color : source_color;


void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	// Called for every vertex the material is visible on.
}

void fragment() {
	float vignette = texture(spotlight, UV).x;
	ALBEDO = vignette_color.rgb;
	ALPHA = 1.0 - vignette;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
