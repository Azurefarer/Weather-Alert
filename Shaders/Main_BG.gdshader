shader_type canvas_item;

const int num_sines = 32;
const int max_inst = 8;

// Interactability with UI
uniform vec2[max_inst] hover;
uniform float[max_inst] time_since_hover;

// Wave data
uniform float _VertexVelocityMult : hint_range(0.0, 3.0);
uniform float _VertexVelocity : hint_range(0.0, 50.0);
uniform float _VertexWavelengthMult : hint_range(0.0, 2.0);
uniform float _VertexWavelength : hint_range(0.0, 1000.0);
// Ripple data
uniform float _RippleVelocityMult : hint_range(0.0, 3.0) = 0.6;
uniform float _RippleVelocity : hint_range(0.0, 50.0) = 16.0;
uniform float _RippleWavelengthMult : hint_range(0.0, 2.0) = 0.5;
uniform float _RippleWavelength : hint_range(0.0, 1000.0) = 150.0;
uniform float _WaveGroupVelocity : hint_range(0.0, 1000.0) = 250.0;
uniform float _DispersionCoeff : hint_range(0.0, 2.0, 0.005) = 0.8;
uniform float _RipplePeakWidth : hint_range(0.0, 100.0) = 13.0;
uniform float wave_time;
uniform int num_inst;
uniform float intensity : hint_range(0.0, 1.0, 0.05) = 0.25;

struct Wave {
	vec2[num_sines] v; // phase velocity
	vec2 pos; // position
	vec2[num_sines] f; // frequency
	vec2[num_sines] w; // wavelength
	vec2[num_sines] p; // phase
	vec2[num_sines] a; // amplitude
	vec2[num_sines] vg; // group velocity
};

// params: wave obj, phase velocity, phase velocity mult, wavelength, wavelength mult
// group velocity, group velocity mult(dispersion)
Wave wave_gen(Wave w, float v, float vm, float wav, float wavm, float vg, float vgm) {
	for (int i = 0; i <= (num_sines-1); i++) {
		w.w[i] = vec2(2.0 * PI / wav); // Wave number
		w.v[i] = vec2(v);
		w.a[i] = vec2((1.0 / sqrt(2.0)) * exp(-pow(w.w[i].x, 2.0)/4.0));
		w.f[i] = vec2(w.w[i] * v); // angular frequency
		w.p[i] = vec2(w.v[i] * (2.0 * PI / w.w[i]));
		w.vg[i] = vec2(vg);
		v *= vm;
		wav *= wavm;
		vg *= vgm;
	}
	return w;
}

// Use polar coords cause it's cleaner -> sum up wave forms -> send to wave_data
float sum_of_sines(float time, Wave w) {
	float wave_data;
	float rings = 0.0;
	float packet = 0.0;
	vec2 polar_pos = vec2(sqrt(pow(w.pos.x, 2.0) + pow(w.pos.y, 2.0)), atan(w.pos.x, w.pos.y));
	for (int i = 0; i <= (num_sines-1); i++) {
		float hr = w.a[i].x * cos(w.w[i].x * polar_pos.x - w.f[i].x * time);
		float htheta = w.a[i].y * cos(w.w[i].y * polar_pos.y);
		rings += hr + htheta;
	}
	rings = rings * (1.0 / sqrt(2.0 * PI));
	wave_data = rings;
	return wave_data;
}

// Use polar coords cause it's cleaner -> sum up gaussian wave packets -> send to ripple_data
float wave_packet(float time, Wave w) {
	float ripple_data;
	float packet = 0.0;
	vec2 polar_pos = vec2(sqrt(pow(w.pos.x, 2.0) + pow(w.pos.y, 2.0)), atan(w.pos.x, w.pos.y));
	for (int i = 0; i <= (num_sines-1); i++) {
		// Gaussian Wave Packet
		packet += w.a[i].x * exp(-0.5 * pow((polar_pos.x - time * w.vg[i].x) / _RipplePeakWidth, 2.0)) * cos(w.w[i].x * polar_pos.x - w.f[i].x * 1.0*time*w.v[i].x);
	}
	ripple_data = packet;
	return ripple_data;
}

void vertex() {

}

void fragment() {
	// Create vert data in the case of moving BG wave
	vec2 vert = VERTEX;

	// Construct the BG wave at the UI button position
	Wave _wave;
		_wave = wave_gen(_wave, _VertexVelocity, _VertexVelocityMult, _VertexWavelength, _VertexWavelengthMult, _WaveGroupVelocity, _DispersionCoeff);
		_wave.pos = vec2(vert.x, vert.y);
	float wave_data = sum_of_sines(TIME, _wave);

	// Send BG wave to output
	COLOR *= vec4(vec3(wave_data)*0.4, 1.0);

	// Construct a wave at the UI button position
	Wave _wave_ripple;
		_wave_ripple = wave_gen(_wave_ripple, _RippleVelocity, _RippleVelocityMult, _RippleWavelength, _RippleWavelengthMult, _WaveGroupVelocity, _DispersionCoeff);
	for (int i=0; i<= num_inst; i++) {
		if (hover[i] != vec2(0.0, 0.0)) {
			vec2 vert_hover = vec2(VERTEX.x - hover[i].x, VERTEX.y - hover[i].y);
			// Set position data BEFORE sending it to the generator
			_wave_ripple.pos = vert_hover;
			float ripple_data = wave_packet(time_since_hover[i], _wave_ripple);
			// Send ripple instances to output
			// Have ripple amplitude decay over time(parabolic) as f(t) = (amp/wave_time^2)*(time-wave_time)^2
			COLOR += vec4(vec3((clamp(ripple_data, -0.5, 10.0) / pow(wave_time, 2.0)) * pow(time_since_hover[i] - wave_time, 2.0))*intensity, 0.5);
		}
	}
}
