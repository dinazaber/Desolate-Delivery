global uniform sampler2D top_down_shadow_map : filter_linear, repeat_disable;
global uniform int filter_type;
global uniform float filter_scale : hint_range(0.1, 3.0) = 1.0;

float godot_dither_noise(vec2 position) {
	return fract(52.9829189 * fract(dot(position, vec2(0.06711056, 0.00583715))));
}

float sample_shadow_vogel_16(vec2 uv, vec3 world_pos) {
	vec2 texture_size = vec2(textureSize(top_down_shadow_map, 0));
	vec2 radius = (vec2(1.0) / texture_size) * filter_scale;

	float noise = godot_dither_noise(world_pos.xz * 100.0);
	float random_angle = noise * 6.28318530718;

	float cos_a = cos(random_angle);
	float sin_a = sin(random_angle);

	float shadow_total = 0.0;
	const int SAMPLES = 16;
	const float GOLDEN_ANGLE = 2.399963; 

	for (int i = 0; i < SAMPLES; i++) {
		float r = sqrt(float(i) + 0.5) / sqrt(float(SAMPLES));
		float theta = float(i) * GOLDEN_ANGLE;

		vec2 sample_offset = vec2(cos(theta), sin(theta)) * r;
		vec2 rotated_offset = vec2(
		    sample_offset.x * cos_a - sample_offset.y * sin_a,
		    sample_offset.x * sin_a + sample_offset.y * cos_a
		);
	    
		shadow_total += texture(top_down_shadow_map, uv + rotated_offset * radius).a;
	}

	return shadow_total / float(SAMPLES);
}

float sample_shadow_pcf_9(vec2 uv) {
	vec2 texture_size = vec2(textureSize(top_down_shadow_map, 0));
	vec2 texel_offset = (vec2(1.0) / texture_size) * filter_scale;
	float shadow_total = 0.0;

	for (float x = -1.0; x <= 1.0; x += 1.0) {
    	for (float y = -1.0; y <= 1.0; y += 1.0) {
		vec2 offset = vec2(x, y) * texel_offset;
		shadow_total += texture(top_down_shadow_map, uv + offset).a;
	    }
	}
	return shadow_total / 9.0;
}

float sample_shadow_pcf_4(vec2 uv) {
	vec2 texture_size = vec2(textureSize(top_down_shadow_map, 0));
	vec2 texel_offset = (vec2(0.5) / texture_size) * filter_scale;

	float shadow_total = 0.0;
	shadow_total += texture(top_down_shadow_map, uv + vec2(-1.0, -1.0) * texel_offset).a;
	shadow_total += texture(top_down_shadow_map, uv + vec2(1.0, -1.0) * texel_offset).a;
	shadow_total += texture(top_down_shadow_map, uv + vec2(-1.0, 1.0) * texel_offset).a;
	shadow_total += texture(top_down_shadow_map, uv + vec2(1.0, 1.0) * texel_offset).a;

	return shadow_total * 0.25;
}