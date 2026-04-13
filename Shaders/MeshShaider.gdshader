shader_type spatial;
render_mode unshaded, cull_disabled;

// Details (Still using these for the "Projected" textures)
uniform sampler2D mask_palette : source_color, filter_nearest;

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
uniform float light_x = 0.5;
uniform float light_y = 0.5;
uniform float light_z = 0.5;
uniform float facet_intensity = 0.5;

group_uniforms Instances;
uniform vec3 color0: source_color;
uniform vec3 color1: source_color;
uniform vec3 color2: source_color;
uniform vec3 color3: source_color;
uniform vec3 color4: source_color;
uniform vec3 color5: source_color;
uniform vec3 color6: source_color;
uniform int i = 1;

varying flat int index;

varying vec3 worldPos;
varying vec3 world_normal;

// --- THE OPTIMIZED BOX PROJECTION FUNCTION ---
vec4 get_box_projection(sampler2D p_sampler, vec3 p_normal, vec3 p_pos) {
    vec3 abs_n = abs(p_normal);
    vec2 uv;
    
    if (abs_n.x > abs_n.y && abs_n.x > abs_n.z) {
        uv = p_pos.zy;
    } else if (abs_n.y > abs_n.x && abs_n.y > abs_n.z) {
        uv = p_pos.xz;
    } else {
        uv = p_pos.xy;
    }
    
    return texture(p_sampler, uv);
}

void vertex(){
    worldPos = VERTEX;
    world_normal = NORMAL;
	
	index = (INSTANCE_ID / i) % 7;
	
    
}

void fragment() {
	
	float mask = UV.x;
	
	vec3 palette[7];
    palette[0] = color0;
    palette[1] = color1;
    palette[2] = color2;
    palette[3] = color3;
	palette[4] = color4;
	palette[5] = color5;
	palette[6] = color6;
	
	vec3 target_color = palette[index];
	
	
    // 1. Get Base Color directly from Vertex Color (First Layer)
    vec3 base_color = COLOR.rgb;
    
    // 2. Identify the mask from the varying we passed (Layer 2)
    vec3 d_id = texture(mask_palette, UV2).rgb;
    
    vec3 out_color = base_color;
	
	out_color = mix(out_color, target_color, mask);
	
    vec3 n = normalize(world_normal);
    
    // 3. Sample textures using Box Projection based on Vertex Mask
    // Note: Since Face Corner is sharp, d_id.r > 0.5 is very reliable
    
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
	
    
    // --- LIGHTING ---
    vec3 light_dir = normalize(vec3(light_x, light_y, light_z));
    float lum = dot(n, light_dir);
    float final_diffuse = mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity);
	
	

    ALBEDO = out_color * final_diffuse;
}
