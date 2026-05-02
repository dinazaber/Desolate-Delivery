// Use this shader on objects that use only 1 detail textures

shader_type spatial;
render_mode cull_disabled;

group_uniforms Detail;
uniform sampler2D detail1 : source_color, filter_linear;
uniform float detail1_scale = 1.0;
uniform float alpha1 = 1.0;

varying vec3 worldPos;
varying vec3 world_normal;


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
    worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	
	// --- DETAILS ---
    vec3 base_color = COLOR.rgb;
    vec3 out_color = base_color;
	
    vec3 n = normalize(world_normal);
    
    // Sample textures using Box Projection based on Vertex Mask
	vec4 tex = get_box_projection(detail1, n, worldPos * detail1_scale);
    out_color = mix(out_color, tex.rgb, tex.a * alpha1);
	
    ALBEDO = out_color;
}
