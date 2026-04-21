shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, blend_mix;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D sand_noise : repeat_enable;
uniform vec3 sand_color : source_color = vec3(0.76, 0.6, 0.4);
uniform float storm_density = 0.5;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// 1. Get Scene Depth
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	// 2. Reconstruct World Direction
	vec3 ray_dir = (INV_VIEW_MATRIX * vec4(view.xyz, 0.0)).xyz;
	vec3 cam_pos = INV_VIEW_MATRIX[3].xyz;

	// 3. Multi-Layer Sand Simulation
	// We sample the noise 3 times at different scales/speeds to fake 3D volume
	float noise_accum = 0.0;
	
	// Layer 1: Distant, slow-moving dust
	vec2 uv1 = (cam_pos.xz + ray_dir.xz * 10.0) * 0.02 + TIME * 0.05;
	noise_accum += texture(sand_noise, uv1).r * 0.5;
	
	// Layer 2: Mid-range swirls
	vec2 uv2 = (cam_pos.xz + ray_dir.xz * 5.0) * 0.05 - TIME * 0.08;
	noise_accum += texture(sand_noise, uv2).r * 0.3;
	
	// Layer 3: Close-up "flying" grains
	vec2 uv3 = (cam_pos.xz + ray_dir.xz * 2.0) * 0.1 + TIME * 0.15;
	noise_accum += texture(sand_noise, uv3).r * 0.2;

	// 4. Apply distance falloff so sand isn't "inside" the camera lens
	float fog_factor = 1.0 - exp(-linear_depth * storm_density);
	
	// 5. Final Output
	ALBEDO = sand_color;
	// The Alpha is a mix of the total density and our layered noise
	ALPHA = clamp(fog_factor * noise_accum, 0.0, 1.0);
}
