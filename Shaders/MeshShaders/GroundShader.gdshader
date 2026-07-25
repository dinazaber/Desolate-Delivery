shader_type spatial;
render_mode cull_back, specular_disabled;

group_uniforms Adjustments;
uniform vec3 color: source_color;
uniform float light_x = 0.5;
uniform float light_y = 0.5;
uniform float light_z = 0.5;
uniform float facet_intensity = 0.5;

group_uniforms Detail;
uniform sampler2D detail1 : source_color, filter_linear;
uniform float detail1_scale = 1.0;
uniform float alpha1 = 1.0;

// We use a varying to pass the calculated light value to the fragment shader
varying float final_diffuse;
varying vec3 worldPos;
varying vec3 world_normal;

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
    vec4 color1 = vec4(0.0);
    
    // We still write three logic blocks, but the GPU only 
    // executes the ones where the weight is > 0
    if (weights.x > 0.0) {
        color1 += texture(p_sampler, p_pos.zy) * weights.x;
    }
    if (weights.y > 0.0) {
        color1 += texture(p_sampler, p_pos.xz) * weights.y;
    }
    if (weights.z > 0.0) {
        color1 += texture(p_sampler, p_pos.xy) * weights.z;
    }

    return color1;
}

void vertex() {
	
    // --- LIGHTING --
	
	vec3 n = normalize(NORMAL);
    vec3 light_dir = normalize(vec3(light_x, light_y, light_z));
    
    float lum = dot(n, light_dir);
    final_diffuse = (mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity));
	
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	
}

void fragment() {
    // The GPU automatically interpolates v_final_diffuse across the pixels
	vec3 n = normalize(world_normal);
	vec4 tex = get_box_projection(detail1, n, worldPos * detail1_scale);
	vec3 out_color = color;
    out_color = mix(out_color, tex.rgb, tex.a * alpha1);
    ALBEDO = out_color * final_diffuse;
}
