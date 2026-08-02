shader_type spatial;
render_mode cull_back, specular_disabled;

group_uniforms Shader_Settings;
uniform bool enable_wireframe = true;
uniform bool is_multimesh = false;
uniform bool is_weapon = false;
uniform bool enable_world_projection = true;
uniform bool has_rig = false;
uniform bool enable_detail_1 = true;
uniform bool enable_detail_2 = true;
uniform bool enable_glow = false;

#include "MainShaderInclude.gdshaderinc"

// Varyings to bridge tracking data from vertex to fragment stage
varying vec3 pre_skinned_pos;
varying vec3 normal;
varying vec3 vert;
varying vec2 UV3;
varying vec2 UV4;
varying flat int index;

void vertex() {
	pre_skinned_pos = CUSTOM1.rgb; //pre skinned data
	
	UV3 = CUSTOM0.xy;
	UV4 = CUSTOM0.zw;
	
	normal = NORMAL;
	vert = VERTEX;
	
	index = (INSTANCE_ID / group_size) % color_variants;
	
	// Places weapons on top of everything
	vec4 clip_position = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);
	if (is_weapon) clip_position.z = mix(clip_position.z, clip_position.w, 0.9);
	POSITION = clip_position;
}

void fragment() {
	vec3 resolved_pos;
	vec3 resolved_normal;
	
	if (enable_world_projection) {
		// --- WORLD TRIPLANAR ---
		resolved_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		resolved_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	} 
	else if (has_rig){
		// --- RIG ---
		resolved_pos = pre_skinned_pos;
		resolved_normal = cross(dFdx(pre_skinned_pos), dFdy(pre_skinned_pos));
	}
	else{
		// OBJECT BASED ---
		resolved_pos = vert;
		resolved_normal = normal;
	}
	
	// --- ALBEDO PROCESSING ---
    vec3 out_color = COLOR.rgb; 
	if (is_multimesh && (distance(COLOR.rgb, vec3(1.0)) < 0.001)) out_color = palette[index]; // Multimesh color replacement
	
    resolved_normal = normalize(resolved_normal);
    
    // Apply Detail Layer 1 Mask Blend
    if (UV3.x >= 0.4 && enable_detail_1 && UV3.y < 0.9) { 
        vec4 tex = get_box_projection(detail1, resolved_normal, resolved_pos * detail1_scale);
		out_color = mix(out_color, tex.rgb, tex.a * alpha1);
    }
    
    // Apply Detail Layer 2 Mask Blend
    if (UV3.x <= 0.6 && enable_detail_2 && UV3.y < 0.9) { 
        vec4 tex = get_box_projection(detail2, resolved_normal, resolved_pos * detail2_scale);
        out_color = mix(out_color, tex.rgb, tex.a * alpha2);
    }
	
	// --- GLOW ENGINE ---
	EMISSION = calculate_glow(enable_glow, UV4.x, out_color);
	
	// --- WIREFRAME RENDER PIPELINE ---
	if (enable_wireframe) ALBEDO = apply_wireframe(out_color, UV, VERTEX);
	else ALBEDO = out_color;
}