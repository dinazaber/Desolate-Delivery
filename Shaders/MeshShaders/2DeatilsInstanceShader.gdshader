// Use this shader on MultiMeshInstance meshes that use 2 detail textures

shader_type spatial;
render_mode unshaded, cull_disabled;

// Details (Still using these for the "Projected" textures)
uniform sampler2D mask_palette : source_color, filter_nearest;

group_uniforms Wireframe;
uniform vec3 wire_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float wire_width : hint_range(0.0, 0.2) = 0.01; // Width in meters
uniform float wire_transparency : hint_range(0.0, 1.0) = 0.5;

group_uniforms Detail1;
uniform sampler2D detail1 : source_color, filter_linear;
uniform float detail1_scale = 1.0;
uniform float alpha1 = 1.0;

group_uniforms Detail2;
uniform sampler2D detail2 : source_color, filter_linear;
uniform float detail2_scale = 1.0;
uniform float alpha2 = 1.0;

group_uniforms Lighting_Adjustments;
uniform float light_x = 0.5;
uniform float light_y = 0.5;
uniform float light_z = 0.5;
uniform float facet_intensity = 0.5;

group_uniforms Instances;
uniform vec3 palette[15] : source_color;
uniform int color_variants: hint_range(0, 15) = 1;
uniform int i = 1;

varying flat int index;

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
	
	index = (INSTANCE_ID / i) % color_variants;
	
	uv3 = CUSTOM0.xy;
    
}

void fragment() {
	
	// --- DETAILS ---
	float mask = uv3.x; // Instance mask
	vec3 target_color = palette[index];
    vec3 base_color = COLOR.rgb;
    
    // Identify the mask from the varying we passed (UV2)
    vec3 d_id = texture(mask_palette, UV2).rgb;
    vec3 out_color = base_color;
	
	out_color = mix(out_color, target_color, mask);
	
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
	
    
    // --- LIGHTING ---
    vec3 light_dir = normalize(vec3(light_x, light_y, light_z));
    float lum = dot(n, light_dir);
    float final_diffuse = mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity);
	
	// --- WIREFRAME ---
	
	vec2 uv = UV;
    
    // Distance to edge in UV space
    vec2 dist_to_edge = min(uv, 1.0 - uv);
    
    // Get the screen-space change of UVs
    vec2 d_uv = fwidth(uv);
    
    // We calculate how many meters are in one screen pixel at this depth
    float pixel_to_meter = length(fwidth(VERTEX));
    
    // Convert UV distance to Meters
    // We divide UV distance by (UV-per-pixel) to get pixels, 
    // then multiply by (Meters-per-pixel) to get meters.
    vec2 dist_in_meters = (dist_to_edge / max(d_uv, 0.0001)) * pixel_to_meter;
    float closest_dist = min(dist_in_meters.x, dist_in_meters.y);
    
    // Create the crisp mask
    float wire_mask = 1.0 - smoothstep(wire_width, wire_width + 0.002, closest_dist);
	
	vec3 blended_wire = mix(out_color * final_diffuse, wire_color.rgb, wire_transparency);
	
    ALBEDO = mix(out_color * final_diffuse, blended_wire, wire_mask);
}
