shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_back, diffuse_burley, shadows_disabled;

uniform float alpha : hint_range(0.0, 1.0) = 0.5;
uniform float rim_power : hint_range(0.0, 5.0) = 1.0;

uniform float camera_fade_start : hint_range(0.0, 5.0) = 0.5;
uniform float camera_fade_end : hint_range(0.0, 10.0) = 2.0;

// Controls how much noise blends into the alpha channel to break up the rings
uniform float dither_strength : hint_range(0.0, 0.1) = 0.015;

uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D gradient : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;

uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 1.0) = 0.5;
uniform vec3 uv1_scale = vec3(5.0, 0.0, 0.0);
uniform vec3 uv1_offset = vec3(0.0, 1.0, 0.0);

varying vec2 base_uv;

vec2 rotateUV(vec2 uv) {
	return vec2(1.0 * (uv.y - 0.5) + 0.5, -1.0 * (uv.y - 0.5) + 0.5);
}

// Interleaved Gradient Noise function - extremely cheap for mobile performance
float get_dither(vec2 screen_pos) {
	vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
	return fract(magic.z * fract(dot(screen_pos, magic.xy)));
}

void vertex() {
	base_uv = rotateUV(UV);
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	vec3 fallof = texture(gradient, base_uv).rgb;
	
	float fresnel = pow(1.0 - dot(normalize(NORMAL), normalize(VIEW)), rim_power);
	float fade = mix(1.0, -1.0, fresnel);

	ROUGHNESS = 0.0; 
	SPECULAR = 0.0;
	
	vec3 emission_tex = texture(texture_emission, UV).rgb;
	EMISSION = (emission.rgb + emission_tex) * emission_energy * fallof;
	
	float camera_dist = -VERTEX.z;
	float camera_proximity_fade = smoothstep(camera_fade_start, camera_fade_end, camera_dist);
	
	// Calculate base alpha
	float base_alpha = clamp(fade, 0.0, 1.0) * EMISSION.r * alpha * camera_proximity_fade;
	
	// Generate dither noise based on screen pixel coordinates
	float noise = get_dither(FRAGCOORD.xy);
	
	// Apply dither offset specifically when alpha is sliding through partial gradients
	// We center the noise around 0 (-0.5 to 0.5) so it doesn't artificially brighten/darken the whole object
	ALPHA = base_alpha + (noise - 0.5) * dither_strength;
}