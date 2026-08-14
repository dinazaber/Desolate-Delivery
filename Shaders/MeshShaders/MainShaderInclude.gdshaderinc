#ifndef EFFECTS_INCLUDED
#define EFFECTS_INCLUDED

group_uniforms Wireframe;
uniform vec3 wire_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float wire_width : hint_range(0.0, 5.0) = 1.0; 
uniform float wire_transparency : hint_range(0.0, 1.0) = 0.5;

group_uniforms Detail1;
uniform sampler2D detail1 : source_color, filter_linear;
uniform float detail1_scale = 1.0;
uniform float alpha1 = 1.0;

group_uniforms Detail2;
uniform sampler2D detail2 : source_color, filter_linear;
uniform float detail2_scale = 1.0;
uniform float alpha2 = 1.0;

group_uniforms Glow;
uniform float glow_intensity = 1.0;
uniform vec3 glow_color_override: source_color;
uniform bool glow_override = true;

group_uniforms Instances;
uniform vec3 palette[8] : source_color;
uniform int color_variants: hint_range(0, 8) = 1;
uniform int group_size = 1;


// Box projection to place details
vec4 get_box_projection(sampler2D p_sampler, vec3 p_normal, vec3 p_pos) {
    vec3 n = abs(normalize(p_normal));
    vec3 weights = n;

    float low_mask = min(min(weights.x, weights.y), weights.z);
    weights -= low_mask; 
    weights /= (weights.x + weights.y + weights.z);

    vec4 color = vec4(0.0);
    if (weights.x > 0.0) { color += texture(p_sampler, p_pos.zy) * weights.x; }
    if (weights.y > 0.0) { color += texture(p_sampler, p_pos.xz) * weights.y; }
    if (weights.z > 0.0) { color += texture(p_sampler, p_pos.xy) * weights.z; }

    return color;
}

// Computes the emission color based on glow settings and mask criteria
vec3 calculate_glow(bool enable, float mask_val, vec3 base_color) {
    if (enable && mask_val > 0.9) {
        if (!glow_override) return base_color * glow_intensity;
        else return glow_color_override * glow_intensity;
    }
    
    return vec3(0.0);
}

vec3 apply_wireframe(vec3 base_color, vec2 uv, vec3 vertex_pos) {
    vec2 dist_to_edge = min(uv, 1.0 - uv);
    vec2 derivative = max(fwidth(uv), vec2(0.00001));

    float depth = abs(vertex_pos.z);
    
    // Distance factor (1.0 close up, 0.0 far away)
    float near_dist = 2.0;
    float far_dist = 60.0;
    float distance_factor = 1.0 - smoothstep(near_dist, far_dist, depth);

    // Calculate base edge distance in screen pixels
    vec2 pixel_dist = dist_to_edge / derivative;
    float closest_pixel_edge = min(pixel_dist.x, pixel_dist.y);

    // Scale thickness down inversely with depth to preserve visual perspective
    // Dividing by max(depth, 1.0) shrinks screen-space width as object gets further
    float target_thickness = wire_width * (near_dist / max(depth, near_dist));
    
    // Clamp to sub-pixel minimum so it doesn't pop out abruptly before far_dist
    float final_thickness = max(target_thickness, 0.25);

    // Anti-aliased wire mask
    float wire_mask = 1.0 - smoothstep(final_thickness - 0.5, final_thickness + 0.5, closest_pixel_edge);

    // Smooth distance fadeout
    wire_mask *= distance_factor;

    vec3 blended_wire = mix(base_color, wire_color, wire_transparency);
    return mix(base_color, blended_wire, wire_mask);
}

#endif