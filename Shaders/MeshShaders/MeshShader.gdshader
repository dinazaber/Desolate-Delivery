// Use this shader on objects that use only 2 detail textures

shader_type spatial;
render_mode cull_back;

uniform bool enable_world_projection = false;
uniform bool enable_detail_1 = true;
uniform bool enable_detail_2 = true;
uniform bool enable_glow = false;

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

group_uniforms Glow;
uniform vec3 glow_color: source_color;
uniform float glow_intensity = 1.0;

varying vec3 worldPos;
varying vec3 world_normal;
varying vec2 UV3;
varying vec2 UV4;


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
	
	if (enable_world_projection){
		worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	}
	
	UV3 = CUSTOM0.xy;
	
	UV4 = CUSTOM0.zw;
}

void fragment() {
	
	// --- DETAILS ---
    vec3 base_color = COLOR.rgb;
    vec3 out_color = base_color;
	
    vec3 n = normalize(world_normal);
    
    // Sample textures using Box Projection based on Vertex Mask
    if (UV3.x >= 0.4 && enable_detail_1 && UV3.y > 0.1) {
        vec4 tex = get_box_projection(detail1, n, worldPos * detail1_scale);
        out_color = mix(out_color, tex.rgb, tex.a * alpha1);
    }
    
    if (UV3.x <= 0.6  && enable_detail_2 && UV3.y > 0.1) {
        vec4 tex = get_box_projection(detail2, n, worldPos * detail2_scale);
        out_color = mix(out_color, tex.rgb, tex.a * alpha2);
    }
	
	// --- GLOW ---
	EMISSION = vec3(0.0);
	if (enable_glow){
		if(UV4.x > 0.9){
			EMISSION = glow_color * glow_intensity;
		}
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
