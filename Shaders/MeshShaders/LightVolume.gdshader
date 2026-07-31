shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

group_uniforms General;
uniform bool proximity_fade = true;
uniform float proximity_fade_distance : hint_range(0.0, 4096.0, 0.01) = 1.0;
uniform bool distance_fade = true;
uniform float distance_fade_min : hint_range(0.0, 4096.0, 0.01) = 0;
uniform float distance_fade_max : hint_range(0.0, 4096.0, 0.01) = 1.0;

group_uniforms Light_Settings;
uniform sampler2D light_gradient_tex : hint_default_black, filter_linear;
uniform vec4 light_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform float light_intensity : hint_range(0.0, 5.0) = 1.5;

group_uniforms Dust_Settings;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 dust_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float dust_density = 4.0;
uniform vec2 dust_speed = vec2(0.02, 0.01);
uniform float dust_brightness : hint_range(0.0, 10.0) = 3.0;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

void fragment() {
    //Sample Light Gradient (Your beam texture)
    vec4 light_sample = texture(light_gradient_tex, UV);
    vec3 light_beam = light_sample.rgb * light_color.rgb * light_intensity * light_sample.a;

    //Generate Dust Specks (Dual scrolling noise)
    vec2 uv1 = UV * dust_density + TIME * dust_speed;
    vec2 uv2 = UV * (dust_density * 1.6) - TIME * (dust_speed * 0.8);

    float n1 = texture(noise_tex, uv1).r;
    float n2 = texture(noise_tex, uv2).r;

    // Isolate bright noise peaks into tiny distinct specks
    float specks = pow(n1 * n2, 4.0);
    specks = smoothstep(0.01, 0.15, specks);

    //Mask dust by the light gradient alpha so dust ONLY exists inside the light beam
    vec3 dust_motes = dust_color.rgb * specks * dust_brightness * light_sample.a;

    //Combine both into a single additive output
    ALBEDO = light_beam + dust_motes;
    ALPHA = clamp(light_sample.a + specks, 0.0, 1.0);
	
	// Proximity Fade
	if (proximity_fade){
		float proximity_depth_tex = textureLod(depth_texture, SCREEN_UV, 0.0).r;
		vec4 ndc = OUTPUT_IS_SRGB ? vec4(vec3(SCREEN_UV, proximity_depth_tex) * 2.0 - 1.0, 1.0) : vec4(SCREEN_UV * 2.0 - 1.0, proximity_depth_tex, 1.0);
		vec4 proximity_view_pos = INV_PROJECTION_MATRIX * ndc;
		proximity_view_pos.xyz /= proximity_view_pos.w;
		ALPHA *= clamp(1.0 - smoothstep(proximity_view_pos.z + proximity_fade_distance, proximity_view_pos.z, VERTEX.z), 0.0, 1.0);
	}
	
	// Distance Fade
	if (distance_fade) ALPHA *= clamp(smoothstep(distance_fade_min, distance_fade_max, length(VERTEX)), 0.0, 1.0);
}