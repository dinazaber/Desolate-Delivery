// Use this shader on MultiMeshInstance meshes that use 3 detail textures

shader_type spatial;
render_mode unshaded, cull_disabled;

// Details (Still using these for the "Projected" textures)
uniform sampler2D mask_palette : source_color, filter_nearest;

group_uniforms Wireframe;
uniform vec3 wire_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float wire_width : hint_range(0.0, 5) = 2;
uniform float wire_transparency : hint_range(0.0, 1.0) = 0.5;

group_uniforms Detail1;
uniform sampler2D detail1 : source_color, filter_linear;
uniform float detail1_scale = 1.0;
uniform float alpha1 = 1.0;

group_uniforms Detail2;
uniform sampler2D detail2 : source_color, filter_linear;
uniform float detail2_scale = 1.0;
uniform float alpha2 = 1.0;

group_uniforms Detail3;
uniform sampler2D detail3 : source_color, filter_linear;
uniform float detail3_scale = 1.0;
uniform float alpha3 = 1.0;

group_uniforms Lighting_Adjustments;
uniform float facet_intensity = 0.5;
global uniform vec3 sun_direction;

group_uniforms Instances;
uniform vec3 palette[7] : source_color;
uniform int color_variants: hint_range(0, 15) = 1;
uniform int i = 1;

varying flat int index;

varying vec3 worldPos;
varying vec3 world_normal;
varying vec2 uv3;
varying float final_diffuse;

// --- THE OPTIMIZED BOX PROJECTION FUNCTION ---
vec4 get_box_projection(sampler2D p_sampler, vec3 p_normal, vec3 p_pos) {
    vec3 n = abs(normalize(p_normal));
    
    // Create a "sharpness" power. 
    // Higher = sharper transitions (more like your if/else)
    // Lower = smoother transitions (fixes the 45-degree smear)
    vec3 weights = pow(n, vec3(1.0)); 
    weights /= (weights.x + weights.y + weights.z);

    vec4 tex_x = texture(p_sampler, p_pos.zy);
    vec4 tex_y = texture(p_sampler, p_pos.xz);
    vec4 tex_z = texture(p_sampler, p_pos.xy);

    return tex_x * weights.x + tex_y * weights.y + tex_z * weights.z;
}

void vertex(){
    worldPos = VERTEX;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	index = (INSTANCE_ID / i) % color_variants;
	
	uv3 = CUSTOM0.xy;
	
	vec3 light_dir = normalize(-sun_direction); 
    
    float lum = dot(world_normal, light_dir);
    
    final_diffuse = mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity);
	world_normal = NORMAL;
    
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
        vec4 tex_g = get_box_projection(detail3, n, worldPos * detail3_scale);
        out_color = mix(out_color, tex_g.rgb, tex_g.a * alpha3);
    }
    
    if (d_id.b > 0.5) {
        vec4 tex_b = get_box_projection(detail2, n, worldPos * detail2_scale);
        out_color = mix(out_color, tex_b.rgb, tex_b.a * alpha2);
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
	
	vec3 blended_wire = mix(out_color * final_diffuse, wire_color.rgb, wire_transparency);
	
    ALBEDO = mix(out_color * final_diffuse, blended_wire, wire_mask * alpha_fade);
}
