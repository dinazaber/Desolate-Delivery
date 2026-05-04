shader_type spatial;
render_mode cull_back;

// Details (Still using these for the "Projected" textures)
uniform sampler2D mask_palette : source_color, filter_nearest;

group_uniforms Wireframe;
uniform vec3 wire_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float wire_width : hint_range(0.0, 5.0) = 1; // Width in meters
uniform float wire_transparency : hint_range(0.0, 1.0) = 0.5;

group_uniforms Detail1;
uniform sampler2D detail1 : source_color, filter_linear;
uniform float detail1_scale = 1.0;
uniform float alpha1 = 1.0;

group_uniforms Detail2;
uniform sampler2D detail2 : source_color, filter_linear;
uniform float detail2_scale = 1.0;
uniform float alpha2 = 1.0;

group_uniforms Display;
uniform vec3 color_off: source_color;
uniform vec3 color_on: source_color;
uniform int charge_amount: hint_range(0, 4) = 0;

varying vec3 worldPos;
varying vec3 world_normal;
varying vec2 uv3;

// --- THE OPTIMIZED BOX PROJECTION FUNCTION ---
vec4 get_box_projection(sampler2D p_sampler, vec3 p_normal, vec3 p_pos) {
     vec3 n = abs(normalize(p_normal));
    
    // 1. Determine which axis to skip (the smallest one)
    // We create weights that only care about the two strongest directions
    vec3 weights = n;
    
    // This math "zeros out" the smallest component
    float low_mask = min(min(weights.x, weights.y), weights.z);
    weights -= low_mask; 
    
    // Normalize weights so they sum to 1.0
    weights /= (weights.x + weights.y + weights.z);

    // 2. Sample only the two necessary planes
    vec4 color = vec4(0.0);
    
    // We still write three logic blocks, but the GPU only 
    // executes the ones where the weight is > 0
    if (weights.x > 0.0) {
        color += texture(p_sampler, p_pos.zy) * weights.x;
    }
    if (weights.y > 0.0) {
        color += texture(p_sampler, p_pos.xz) * weights.y;
    }
    if (weights.z > 0.0) {
        color += texture(p_sampler, p_pos.xy) * weights.z;
    }

    return color;
}

void vertex(){
    worldPos = VERTEX;
	world_normal = NORMAL;
	uv3 = CUSTOM0.xy;
}

void fragment() {
	vec3 base_color = COLOR.rgb;
	
	// --- DISPLAY ---
	if (uv3.x >= 0.0 && uv3.x <= 1.0){
		int face_id = int(floor((uv3.x + 0.001) * 4.0));
		float mask = (face_id < charge_amount+1) ? 1.0 : 0.0;
		vec3 display_color = mix(color_off, color_on, mask);
		base_color = mix(base_color, display_color, 1.0);
	}
	
	
	// --- DETAILS ---
    // Identify the mask from the varying we passed (UV2)
    vec3 d_id = texture(mask_palette, UV2).rgb;
    vec3 out_color = base_color;
	
    vec3 n = normalize(world_normal);
    
    // Sample textures using Box Projection based on Vertex Mask
    if (d_id.r > 0.5) {
        vec4 tex_r = get_box_projection(detail1, n, worldPos * detail1_scale);
        out_color = mix(out_color, tex_r.rgb, tex_r.a * alpha1);
    }
    
    if (d_id.g > 0.5) {
        vec4 tex_g = get_box_projection(detail2, n, worldPos * detail2_scale);
        out_color = mix(out_color, tex_g.rgb, tex_g.a * alpha2);
    }
	
    
	
	// --- WIREFRAME ---
	vec2 uv = UV;
    vec2 dist_to_edge = min(uv, 1.0 - uv);
    vec2 derivative = fwidth(uv);
    
    float depth = abs(VERTEX.z);
    
    float distance_factor = clamp(1.0 - (depth / 20.0), 0.0, 1.0);
    
    float final_thickness = wire_width * pow(distance_factor, 2.0);
    
    vec2 pixel_dist = dist_to_edge / derivative;
    float closest_pixel_edge = min(pixel_dist.x, pixel_dist.y);
    
    float wire_mask = 1.0 - smoothstep(final_thickness - 0.5, final_thickness + 0.5, closest_pixel_edge);
    
    float alpha_fade = distance_factor; 
	
	vec3 blended_wire = mix(out_color, wire_color.rgb, wire_transparency);
	
    ALBEDO = mix(out_color, blended_wire, wire_mask * alpha_fade);
}
