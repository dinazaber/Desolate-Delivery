shader_type spatial;
render_mode cull_back;

uniform bool enable_wireframe = true;
uniform bool enable_world_projection = true;
uniform bool has_rig = false;
uniform bool enable_detail_1 = true;
uniform bool enable_detail_2 = true;
uniform bool enable_glow = false;

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

// Varyings to bridge tracking data from vertex to fragment stage
varying vec3 pre_skinned_pos;
varying vec3 normal;
varying vec3 vert;
varying vec2 UV3;
varying vec2 UV4;

// --- OPTIMIZED BOX PROJECTION ---
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

void vertex() {
	pre_skinned_pos = CUSTOM1.rgb; //pre skinned data
	
	UV3 = CUSTOM0.xy;
	UV4 = CUSTOM0.zw;
	
	normal = NORMAL;
	vert = VERTEX;
}

void fragment() {
	vec3 resolved_pos;
	vec3 resolved_normal;
	
	if (enable_world_projection) {
		// --- WORLD TRIPLANAR (Environment fallback) ---
		resolved_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		resolved_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	} 
	else if (has_rig){
		resolved_pos = pre_skinned_pos;
		resolved_normal = cross(dFdx(pre_skinned_pos), dFdy(pre_skinned_pos));
	}
	else{
		resolved_pos = vert;
		resolved_normal = normal;
	}
	
	// --- ALBEDO PROCESSING ---
    vec3 base_color = COLOR.rgb; 
    vec3 out_color = base_color;
    vec3 n = normalize(resolved_normal);
    
    // Apply Detail Layer 1 Mask Blend
    if (UV3.x >= 0.4 && enable_detail_1 && UV3.y < 0.9) { 
        vec4 tex = get_box_projection(detail1, n, resolved_pos * detail1_scale);
        out_color = mix(out_color, tex.rgb, tex.a * alpha1);
    }
    
    // Apply Detail Layer 2 Mask Blend
    if (UV3.x <= 0.6 && enable_detail_2 && UV3.y < 0.9) { 
        vec4 tex = get_box_projection(detail2, n, resolved_pos * detail2_scale);
        out_color = mix(out_color, tex.rgb, tex.a * alpha2);
    }
	
	// --- GLOW ENGINE ---
	EMISSION = vec3(0.0);
	if (enable_glow){
		if(UV4.x > 0.9){
			if (!glow_override){ EMISSION = COLOR.rgb * glow_intensity; }
			else { EMISSION = glow_color_override * glow_intensity; }
		}
	}
	
	// --- WIREFRAME RENDER PIPELINE ---
	if (enable_wireframe){
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
	else {
		ALBEDO = out_color;
	}
}