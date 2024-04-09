shader_type canvas_item;

uniform vec2 hover; // Interactability with UI


uniform float _VertexAmplitudeMod : hint_range(0.0, 1.0); // credit to acerola
uniform float _VertexAmplitude : hint_range(0.0, 3.0); // credit to acerola
uniform float _VertexFrequencyMod : hint_range(0.0, 2.0); // credit to acerola
uniform float _VertexFrequency : hint_range(0.0, 2.0); // credit to acerola
uniform float _VertexWavelengthMod : hint_range(0.0, 2.0); // credit to acerola
uniform float _VertexWavelength : hint_range(0.0, 1000.0); // credit to acerola
uniform float _VertexPeakWidth : hint_range(0.0, 1.0);

varying vec2 vert;

void vertex() {
	if (hover != vec2(0.0, 0.0)) {
		vert.x = VERTEX.x + hover.x;
		vert.y = VERTEX.y + hover.y;
	}
}

void fragment() {
	if (hover != vec2(0.0, 0.0)) {
		COLOR = vec4(sin(vert.x/1000.0 + TIME), cos(vert.y/1000.0 + TIME), 0.0, 1.0);
	}
	//COLOR = vec4(VERTEX.x/1000.0, VERTEX.y/1000.0, 0.0, 1.0);
	
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
