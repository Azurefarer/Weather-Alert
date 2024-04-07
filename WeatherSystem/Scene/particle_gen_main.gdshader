shader_type particles;

uniform vec3 gravity;

uniform int Emission_Shape : hint_range (0, 5);
// 0 is planar
uniform int emission_tex_point_count : hint_range(128, 2048);

uniform vec3 emission_shape_offset = vec3(0.);
uniform vec3 emission_shape_scale = vec3(1.);


float rand_from_seed(inout uint seed) {
	int k;
	int s = int(seed);
	if (s == 0)
	s = 305420679;
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0)
		s += 2147483647;
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}


// Display Params
uniform float scale_min;
uniform float scale_max;
uniform float hue_variation_min;
uniform float hue_variation_max;
uniform float anim_speed_min;
uniform float anim_speed_max;
uniform float anim_offset_min;
uniform float anim_offset_max;
uniform float lifetime_randomness;
uniform vec4 color_value : source_color;

struct DisplayParameters{
	vec3 scale;
	float hue_rotation;
	float animation_speed;
	float animation_offset;
	float lifetime;
	vec4 color;
};

void calculate_initial_display_params(inout DisplayParameters params,inout uint alt_seed){
	// -------------------- DO NOT REORDER OPERATIONS, IT BREAKS VISUAL COMPATIBILITY
	// -------------------- ADD NEW OPERATIONS AT THE BOTTOM
	float pi = 3.14159;
	float degree_to_rad = pi / 180.0;
	params.scale = vec3(mix(scale_min, scale_max, rand_from_seed(alt_seed)));
	params.scale = sign(params.scale) * max(abs(params.scale), 0.001);
	params.hue_rotation =  pi * 2.0 * mix(hue_variation_min, hue_variation_max, rand_from_seed(alt_seed));
	params.animation_speed = mix(anim_speed_min, anim_speed_max, rand_from_seed(alt_seed));
	params.animation_offset = mix(anim_offset_min, anim_offset_max, rand_from_seed(alt_seed));
	params.lifetime = (1.0 - lifetime_randomness * rand_from_seed(alt_seed));
	params.color = color_value;
}

// Dynamics Params
uniform float initial_angle_min;
uniform float initial_angle_max;
uniform float angular_velocity_min;
uniform float angular_velocity_max;
uniform float initial_linear_velocity_min;
uniform float initial_linear_velocity_max;
uniform float directional_velocity_min;
uniform float directional_velocity_max;
uniform float radial_velocity_min;
uniform float radial_velocity_max;
uniform float orbit_velocity_min;
uniform float orbit_velocity_max;

struct DynamicsParameters{
	float angle;
	float angular_velocity;
	float initial_velocity_multiplier;
	float directional_velocity;
	float radial_velocity;
	float orbit_velocity;
};

void calculate_initial_dynamics_params(inout DynamicsParameters params,inout uint alt_seed){
	// -------------------- DO NOT REORDER OPERATIONS, IT BREAKS VISUAL COMPATIBILITY
	// -------------------- ADD NEW OPERATIONS AT THE BOTTOM
	params.angle = mix(initial_angle_min, initial_angle_max, rand_from_seed(alt_seed));
	params.angular_velocity = mix(angular_velocity_min, angular_velocity_max, rand_from_seed(alt_seed));
	params.initial_velocity_multiplier = mix(initial_linear_velocity_min, initial_linear_velocity_max,rand_from_seed(alt_seed));
	params.directional_velocity = mix(directional_velocity_min, directional_velocity_max,rand_from_seed(alt_seed));
	params.radial_velocity = mix(radial_velocity_min, radial_velocity_max,rand_from_seed(alt_seed));
	params.orbit_velocity = mix(orbit_velocity_min, orbit_velocity_max,rand_from_seed(alt_seed));
}

// Physical Params
uniform float linear_accel_min;
uniform float linear_accel_max;
uniform float radial_accel_min;
uniform float radial_accel_max;
uniform float tangent_accel_min;
uniform float tangent_accel_max;
uniform float damping_min;
uniform float damping_max;

struct PhysicalParameters{
	float linear_accel;
	float radial_accel;
	float tangent_accel;
	float damping;
};

void calculate_initial_physical_params(inout PhysicalParameters params, inout uint alt_seed){
	params.linear_accel = mix(linear_accel_min, linear_accel_max, rand_from_seed(alt_seed));
	params.radial_accel = mix(radial_accel_min, radial_accel_max, rand_from_seed(alt_seed));
	params.tangent_accel = mix(tangent_accel_min, tangent_accel_max, rand_from_seed(alt_seed));
	params.damping = mix(damping_min, damping_max, rand_from_seed(alt_seed));
}

vec3 calculate_initial_position(inout uint alt_seed) {
	float degree_to_rad = PI / 180.0;
	vec3 pos = vec3(0.);
	if (Emission_Shape == 0) {
		pos = vec3(ivec3(int(rand_from_seed(alt_seed)) % 100));
	}
		//int point = min(emission_texture_point_count - 1, int(rand_from_seed(alt_seed) * float(emission_texture_point_count)));
		//ivec2 emission_tex_size = textureSize(emission_texture_points, 0);
		//ivec2 emission_tex_ofs = ivec2(point % emission_tex_size.x, point / emission_tex_size.x);
		//pos = texelFetch(emission_texture_points, emission_tex_ofs, 0).xyz;
	return pos * emission_shape_scale + emission_shape_offset;
}

uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

void start() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);

	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);
	DynamicsParameters dynamic_params;
	calculate_initial_dynamics_params(dynamic_params, alt_seed);
	PhysicalParameters physics_params;
	calculate_initial_physical_params(physics_params, alt_seed);
	
	if (RESTART_CUSTOM){
		CUSTOM = vec4(0.);
		CUSTOM.w = params.lifetime;
		CUSTOM.x = dynamic_params.angle;
	}
	if (RESTART_COLOR){
		COLOR = params.color;
	}
	if (RESTART_ROT_SCALE) {
		TRANSFORM[0].xyz = vec3(1.0, 0.0, 0.0);
		TRANSFORM[1].xyz = vec3(0.0, 1.0, 0.0);
		TRANSFORM[2].xyz = vec3(0.0, 0.0, 1.0);
	}
	
	if (RESTART_POSITION) {
		TRANSFORM[3].xyz = calculate_initial_position(alt_seed);
		TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
	}
	
	if (RESTART_VELOCITY) {
		VELOCITY = vec3(0.0);
	}
}

void process() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
	
	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);
	DynamicsParameters dynamic_params;
	calculate_initial_dynamics_params(dynamic_params, alt_seed);
	PhysicalParameters physics_params;
	calculate_initial_physical_params(physics_params, alt_seed);
	
	float degree_to_rad = PI / 180.0;
	
	CUSTOM.y += DELTA / LIFETIME;
	CUSTOM.y = mix(CUSTOM.y, 1.0, INTERPOLATE_TO_END);
	
	float lifetime_percent = CUSTOM.y/ params.lifetime;
	if (CUSTOM.y > CUSTOM.w) {
		ACTIVE = false;
	}
	
	vec3 starting_position = TRANSFORM[3].xyz;
	
	
	vec3 force;
	{
		// copied from previous version
		vec3 pos = TRANSFORM[3].xyz;
		force = gravity;
		
		VELOCITY += force * DELTA;
	}
	
	TRANSFORM[3].xyz += VELOCITY * DELTA;
	
	float base_angle = dynamic_params.angle;
	base_angle += CUSTOM.y * LIFETIME * dynamic_params.angular_velocity;
	CUSTOM.x = base_angle * degree_to_rad;
	
	COLOR = params.color;
	TRANSFORM[0].xyz = normalize(TRANSFORM[0].xyz);
	TRANSFORM[1].xyz = normalize(TRANSFORM[1].xyz);
	TRANSFORM[2].xyz = normalize(TRANSFORM[2].xyz);
//	params.scale *= length(final_velocity)/100.0;

	TRANSFORM[0].xyz *= sign(params.scale.x) * max(abs(params.scale.x), 0.001);
	TRANSFORM[1].xyz *= sign(params.scale.y) * max(abs(params.scale.y), 0.001);
	TRANSFORM[2].xyz *= sign(params.scale.z) * max(abs(params.scale.z), 0.001);
	
}
