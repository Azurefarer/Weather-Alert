shader_type spatial;
render_mode skip_vertex_transform;

#define ANIMATE
#define GUASSIAN_DEVIATION
#define LIGHTING
#define DIFFUSE
#define SPECULAR

const int num_sines = 32;

uniform float _VertexAmplitudeMult : hint_range(0.0, 1.0); // credit to acerola
uniform float _VertexAmplitude : hint_range(0.0, 3.0); // credit to acerola
uniform float _VertexFrequencyMult : hint_range(0.0, 2.0); // credit to acerola
uniform float _VertexFrequency : hint_range(0.0, 2.0); // credit to acerola
uniform float _VertexWavelengthMult : hint_range(0.0, 2.0); // credit to acerola
uniform float _VertexWavelength : hint_range(0.0, 1000.0); // credit to acerola
uniform float _VertexPeakWidth : hint_range(0.0, 1.0);

// Coefficients

uniform float _FresnelCoeff : hint_range(0.0, 10.0);
uniform float _SpecCoeff : hint_range(0.0, 10.0);

varying mat4 invViewMat;

struct Wave {
	vec2[num_sines] v; // velocity
	vec2 pos; // position
	vec2[num_sines] f; // frequency
	vec2[num_sines] w; // wavelength
	vec2[num_sines] p; // phase
	vec2[num_sines] a; // amplitude
};

Wave wave_gen(Wave w) {
	float a = _VertexAmplitude;
	float f = _VertexFrequency;
	float wav = _VertexWavelength;
	for (int i = 0; i <= (num_sines-1); i++) {
		w.a[i] = vec2(a);
		w.f[i] = vec2(2.0 * PI * f); // angular frequency
		w.w[i] = vec2(2.0 * PI / wav); // Wave number
		w.v[i] = vec2(w.f[i] / w.w[i]);
		w.p[i] = vec2(w.v[i] * (2.0 * PI / w.w[i]));
		a *= _VertexAmplitudeMult;
		f *= _VertexFrequencyMult;
		wav *= _VertexWavelengthMult;
	}
	return w;
}

vec3 sum_of_sines(float time, Wave w) {
	vec3 wave_data = vec3(0.0);
	float height = 0.0;
	float dwdx = 0.0;
	float dwdz = 0.0;
	vec2 dwdxz = vec2(0.0);
	for (int i = 0; i <= (num_sines-1); i++) {
		float j = float(i) * 45.0 * PI / 180.0;
		float amp = w.a[i].x * w.a[i].y;
		
		// Gaussian deviation
		#ifdef GUASSIAN_DEVIATION
			mat2 rot = mat2(vec2(cos(j), -sin(j)), vec2(sin(j), cos(j)));
			vec2 RotPos = rot * w.pos;
			float x = RotPos.x * w.w[i].x - time * w.f[i].x;
			float z = RotPos.y * w.w[i].y - time * w.f[i].y;
			float s = _VertexPeakWidth;
			float b = pow(sin(x)*cos(z)/s, 2.0);
			height += amp * exp(1.0-b);
			
			// Normals rotate opposite to the geometry so we need to negate the rotation here
			float _dxdx = w.w[i].x*cos(-j);
			float _dzdx = w.w[i].y*sin(-j);
			float _dxdz = -w.w[i].x*sin(-j);
			float _dzdz = w.w[i].y*cos(-j);
			mat2 _Differentials = mat2(vec2(_dxdx, _dxdz), vec2(_dzdx, _dzdz));

			float _Constants = 2.0 * amp / pow(s, 2.0);
			vec2 _TrigFcts = vec2(sin(x) * cos(x) * pow(cos(z), 2.0), -sin(z) * cos(z) * pow(sin(x), 2.0));
			
			dwdxz += -_Constants * (_Differentials * _TrigFcts) * exp(1.0 - b);
			wave_data = vec3(height, dwdxz);
		#else
			// Simplified Guassian
			mat2 rot = mat2(vec2(cos(j), -sin(j)), vec2(sin(j), cos(j)));
			vec2 RotPos = rot * w.pos;
			float x = RotPos.x * w.w[i].x - time * w.f[i].x;
			float z = RotPos.y * w.w[i].y - time * w.f[i].y;
			float a = x + z;
			float s = _VertexPeakWidth;
			float b = pow(sin(a)/s, 2.0);
			height += amp * exp(1.0-b);
			
			float _dxdx = w.w[i].x*cos(j);
			float _dzdx = w.w[i].y*sin(j);
			float _dxdz = -w.w[i].x*sin(j);
			float _dzdz = w.w[i].y*cos(j);				
			mat2 _Differentials = mat2(vec2(_dxdx, _dxdz), vec2(_dzdx, _dzdz));

			float _Constants = 2.0 * amp / pow(s, 2.0);
			float _TrigFctsx = sin(a) * cos(a) * (_dxdx + _dzdx);
			float _TrigFctsz = sin(a) * cos(a) * (_dzdx + _dzdz);
			
//			RotPos = normalize(RotPos);
			dwdx += RotPos.x * _Constants * _TrigFctsx * exp(1.0 - b);
			dwdx += RotPos.y * _Constants * _TrigFctsz * exp(1.0 - b);
			 wave_data = vec3(height, dwdx, dwdz);
		#endif
	}
	return wave_data;
}

void vertex() {
	vec3 world_pos = vec3((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);	
	vec2 p = normalize(world_pos.xz);
	Wave water_wave;
		water_wave = wave_gen(water_wave);
		water_wave.pos = vec2(VERTEX.x, VERTEX.z);
	#ifdef ANIMATE
	vec3 wave_data = sum_of_sines(TIME/10.0, water_wave);
	float wave_height = wave_data.x;
	VERTEX.y = wave_height;	

	TANGENT = normalize(vec3(1.0, wave_data.y, 0.0));
	BINORMAL = normalize(vec3(0.0, wave_data.z, 1.0));
	NORMAL = cross(TANGENT, BINORMAL);
	VERTEX = vec3((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	NORMAL = MODEL_NORMAL_MATRIX * NORMAL;
	#else
	vec3 wave_data = sum_of_sines(0.0, water_wave);
	float wave_height = wave_data.x;
	VERTEX.y = wave_height;	

	TANGENT = normalize(vec3(1.0, wave_data.y, 0.0));
	BINORMAL = normalize(vec3(0.0, wave_data.z, 1.0));
	NORMAL = cross(TANGENT, BINORMAL);
	VERTEX = vec3((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	NORMAL = MODEL_NORMAL_MATRIX * NORMAL;
	#endif
	
//	NORMAL = MODEL_NORMAL_MATRIX * NORMAL;
	
	invViewMat = INV_VIEW_MATRIX;
}

void fragment() {
	vec3 v = normalize((invViewMat * vec4(VIEW, 0.0)).xyz);
	
	ALBEDO = vec3(0.1, 0.3, 0.8);
	
// FIXME: compare to previous water shader on depth detection and further add edge detection.
	
	ALPHA = 1.0 - pow(abs(dot(normalize(NORMAL), -v)), _FresnelCoeff);
//	ALBEDO = NORMAL;
//	METALLIC = 0.0;
//	ROUGHNESS = 0.0;
}

void light() {
	#ifdef LIGHTING
		vec3 light = normalize((invViewMat * vec4(LIGHT, 0.0)).xyz);
		vec3 v = normalize((invViewMat * vec4(VIEW, 0.0)).xyz);
		vec3 norm = normalize(NORMAL);
		#ifdef DIFFUSE
			DIFFUSE_LIGHT += ALBEDO * clamp(dot(norm, -light), 0.0, 1.0);
		#endif
		#ifdef SPECULAR
			vec3 reflight = normalize(reflect(-LIGHT, NORMAL));
			vec3 h = normalize(VIEW + LIGHT);
			float spec = pow(clamp(dot(reflight, VIEW), 0.0, 1.0), _SpecCoeff);
			SPECULAR_LIGHT += spec;
		#endif
	#endif
}
