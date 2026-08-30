shader_type spatial;
render_mode cull_back, depth_draw_never;

// --- Uniforms ---

uniform sampler2D main_tex : source_color, filter_linear_mipmap;
uniform float global_alpha : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D detail_tex : source_color, filter_linear_mipmap;
uniform vec2 detail_tiling = vec2(5.0, 5.0);
uniform float detail_alpha_mult : hint_range(0.0, 1.0) = 1.0;

uniform sampler2D alpha_detail_tex : hint_default_white, filter_linear_mipmap;
uniform vec2 alpha_tiling = vec2(10.0, 10.0);
uniform float fade_start : hint_range(0.0, 1.0) = 0.2;
uniform float fade_end : hint_range(0.0, 1.0) = 0.7;

// Controls how far inward from the edges the decay reaches
uniform float edge_thickness : hint_range(0.0, 1.0) = 0.2;
// Controls how smoothly the edge mask fades out toward the center
uniform float edge_falloff : hint_range(0.01, 1.0) = 0.1;

// NEW: Controls how much noise decay affects the center of the image (0.0 = only borders, 1.0 = whole surface)
uniform float global_decay_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base_color = texture(main_tex, UV);
	
	vec2 detail_uv = UV * detail_tiling;
	vec4 detail_color = texture(detail_tex, detail_uv);
	
	float blended_detail_alpha = detail_color.a * detail_alpha_mult;
	vec3 blended_color = mix(base_color.rgb, detail_color.rgb, blended_detail_alpha);
	
	// --- Masking Math ---
	vec2 distance_to_edge = min(UV, vec2(1.0) - UV);
	float min_dist = min(distance_to_edge.x, distance_to_edge.y);
	
	float edge_mask = 1.0 - smoothstep(edge_thickness - edge_falloff, edge_thickness, min_dist);
	
	vec2 alpha_uv = UV * alpha_tiling;
	float noise_val = texture(alpha_detail_tex, alpha_uv).r;
	
	// Combined mask: blends between the edge-only mask and a constant full-surface value
	float active_mask = max(edge_mask, global_decay_strength);
	
	// Apply the noise to the newly calculated mask area
	float combined_decay = clamp(noise_val * active_mask + (edge_mask * 0.3), 0.0, 1.0);
	
	float noise_fade = 1.0 - smoothstep(fade_start, fade_end, combined_decay);
	
	float final_alpha = base_color.a * noise_fade * global_alpha;
	
	ALBEDO = blended_color;
	ALPHA = final_alpha;
}