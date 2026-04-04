shader_type spatial;
render_mode unshaded, cull_disabled;

// Palettes
uniform sampler2D base_palette : source_color, filter_nearest; //color palette
uniform sampler2D mask_palette : source_color, filter_nearest; //triplanar mask

// Details
group_uniforms Detail1;
uniform sampler2D detail1 : source_color, filter_linear; //red
uniform float detail1_scale = 1.0;
uniform float alpha1 = 1.0;

group_uniforms Detail2;
uniform sampler2D detail2 : source_color, filter_linear; //blue
uniform float detail2_scale = 1.0;
uniform float alpha2 = 1.0;

group_uniforms Detail3;
uniform sampler2D detail3 : source_color, filter_linear; //green
uniform float detail3_scale = 1.0;
uniform float alpha3 = 1.0;

// Triplanar parameters
group_uniforms Triplanar_Settings;
uniform float triplanar_sharpness = 8.0;

group_uniforms Lighting_Adjustments;
uniform float light_x = 0.5;
uniform float light_y = 0.5;
uniform float light_z = 0.5;
uniform float facet_intensity = 0.5;

varying vec3 worldPos;
varying vec3 world_normal;

// Helper function for Triplanar mapping a single texture
vec4 get_triplanar(sampler2D p_sampler, vec3 p_weights, vec3 p_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_pos.zy) * p_weights.x;
	return samp;
}

void vertex(){
	worldPos = VERTEX;
	world_normal = NORMAL;
}

void fragment() {
	// 1. Setup Triplanar Coordinates
	vec3 weights = pow(abs(normalize(world_normal)), vec3(triplanar_sharpness));
	weights /= (weights.x + weights.y + weights.z);
	// World-space position for seamless mapping across objects
	vec3 world_pos_r = worldPos * detail1_scale;
	vec3 world_pos_b = worldPos * detail2_scale;
	vec3 world_pos_g = worldPos * detail3_scale;

	// 2. Identify the Vertex Color (The "ID")
	vec3 base_color = texture(base_palette, UV).rgb;
	vec3 d_id = texture(mask_palette, UV2).rgb;

	// 4. Sample textures only if their mask is active
	// Note: We multiply by mask so inactive textures contribute 0
	vec3 out_color = base_color;
	
	float mask_r = step(0.5, d_id.r);
	float mask_g = step(0.5, d_id.g);
	float mask_b = step(0.5, d_id.b);
	
	// Adding detail1 triplanar
	vec4 tex_r = get_triplanar(detail1, weights, world_pos_r);
	out_color = mix(out_color, tex_r.rgb, tex_r.a * mask_r * alpha1);
	
	// Adding detail2 triplanar
	vec4 tex_b = get_triplanar(detail2, weights, world_pos_b);
	out_color = mix(out_color, tex_b.rgb, tex_b.a * mask_b * alpha2);
	
	// Adding detail3 triplanar
	vec4 tex_g = get_triplanar(detail3, weights, world_pos_g);
	out_color = mix(out_color, tex_g.rgb, tex_g.a * mask_g * alpha3);
	
	vec3 n = normalize(world_normal);
    vec3 light_dir = normalize(vec3(light_x, light_y, light_z));
    vec3 view_dir = normalize(VIEW); // Direction from pixel to camera

    // --- DIFFUSE (Your existing logic) ---
    float lum = dot(n, light_dir);
    float shadow_factor = clamp(lum, 0.0, 1.0);
    float final_diffuse = mix(1.0, shadow_factor, facet_intensity);

	ALBEDO = out_color * final_diffuse;
}