global uniform float shadow_world_size;
global uniform vec2 shadow_camera_center;
global uniform vec3 shadow_color : source_color = vec3(0.1, 0.1, 0.1);

#include "ShadowFilters.gdshaderinc"

float get_orthogonal_shadow(vec3 world_pos, vec3 world_normal) {
	
	vec3 ground_up = vec3(0., 1., 0.);
	float normal_dot = dot(world_normal, ground_up);
	if (normal_dot < 0.25) return 0.0;
	
	// Map world coordinates directly into 0.0 -> 1.0 UV space of the shadow map
	vec2 diff = world_pos.xz - shadow_camera_center;
	vec2 shadow_uv = (diff / shadow_world_size) + vec2(0.5);
	
	// Smoothly fade out the shadow if it approaches the camera's bounding box boundaries
	float edge_fade_x = smoothstep(0.0, 0.1, shadow_uv.x) * smoothstep(1.0, 0.9, shadow_uv.x);
	float edge_fade_y = smoothstep(0.0, 0.1, shadow_uv.y) * smoothstep(1.0, 0.9, shadow_uv.y);
	float boundary_mask = edge_fade_x * edge_fade_y;

	if (shadow_uv.x >= 0.0 && shadow_uv.x <= 1.0 && shadow_uv.y >= 0.0 && shadow_uv.y <= 1.0){
		
		float shadow_sample;

		if (filter_type == 3) shadow_sample = sample_shadow_vogel_16(shadow_uv, world_pos); // Vogel filter

		else if (filter_type == 2) shadow_sample = sample_shadow_pcf_9(shadow_uv); // PCF9 filter

		else if (filter_type == 1) shadow_sample = sample_shadow_pcf_4(shadow_uv); // PCF4 filter

		else shadow_sample = texture(top_down_shadow_map, shadow_uv).a;

		return shadow_sample * boundary_mask;

	}

	return 0.0;

}