shader_type spatial;
render_mode blend_mix, unshaded, cull_back;

uniform sampler2D depth_texture : hint_depth_texture;
uniform float thickness : hint_range(0.5, 20.0, 0.1) = 2.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int samples : hint_range(4, 32) = 4;

uniform float sensitivity : hint_range(0.01, 1.0, 0.01) = 0.1;
uniform float edge_fade : hint_range(0.0, 0.1, 0.001) = 0.015;

// New Uniforms for Distance Fade
uniform float max_distance : hint_range(1.0, 1000.0) = 100.0;
uniform float fade_range : hint_range(1.0, 500.0) = 20.0;

void fragment() {
	vec2 pixel_size = 1.0 / VIEWPORT_SIZE;
	vec2 step_size = pixel_size * thickness;
	float angle_step = TAU / float(samples);
	
	vec3 avg_dx = vec3(0.0);
	vec3 avg_dy = vec3(0.0);
	
	// Sample center depth to calculate distance-based alpha fade
	float center_depth = texture(depth_texture, SCREEN_UV).r;
	vec4 up_center = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, center_depth, 1.0);
	vec3 center_pos = up_center.xyz / up_center.w;
	float dist_to_cam = -center_pos.z; // Depth in view space (Z is negative)

	// Sample in a circle around the pixel
	for (int i = 0; i < samples; i++) {
		float angle = float(i) * angle_step;
		vec2 dir = vec2(cos(angle), sin(angle));
		vec2 offset = dir * step_size;
		
		vec2 uv1 = SCREEN_UV + offset;
		vec2 uv2 = SCREEN_UV - offset;
		
		float d1 = texture(depth_texture, uv1).r;
		float d2 = texture(depth_texture, uv2).r;
		
		vec4 up1 = INV_PROJECTION_MATRIX * vec4(uv1 * 2.0 - 1.0, d1, 1.0);
		vec4 up2 = INV_PROJECTION_MATRIX * vec4(uv2 * 2.0 - 1.0, d2, 1.0);
		
		vec3 diff = (up1.xyz / up1.w) - (up2.xyz / up2.w);
		
		avg_dx += diff * dir.x;
		avg_dy += diff * dir.y;
	}

	float inv_samples = 1.0 / float(samples);
	avg_dx *= inv_samples;
	avg_dy *= inv_samples;

	// Edge detection logic
	vec3 normal = normalize(cross(avg_dy, avg_dx));
	float edge = 1.0 - smoothstep(sensitivity, sensitivity + 0.05, abs(dot(normal, VIEW)));

	// --- FADE LOGIC ---
	
	// 1. Distance Fade: Outlines disappear as they get further away
	// smoothstep(edge_start, edge_end, current_value)
	float distance_fade = smoothstep(max_distance, max_distance - fade_range, dist_to_cam);

	// 2. Viewport Edge Fade: Keeps the edges of the screen clean
	vec2 screen_center_dist = abs(SCREEN_UV - 0.5) * 2.0;
	float max_dist = max(screen_center_dist.x, screen_center_dist.y);
	float vignette = smoothstep(0.0, edge_fade * thickness, 1.0 - max_dist);
	
	// Final composition
	ALBEDO = outline_color.rgb;
	ALPHA = edge * vignette * distance_fade * outline_color.a;
}