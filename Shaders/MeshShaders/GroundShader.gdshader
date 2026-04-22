shader_type spatial;
render_mode cull_disabled;

group_uniforms Adjustments;
uniform vec3 color: source_color;
uniform float light_x = 0.5;
uniform float light_y = 0.5;
uniform float light_z = 0.5;
uniform float facet_intensity = 0.5;

// We use a varying to pass the calculated light value to the fragment shader
varying float final_diffuse;

void vertex() {
	
    // --- LIGHTING --
	
	vec3 n = normalize(NORMAL);
    vec3 light_dir = normalize(vec3(light_x, light_y, light_z));
    
    float lum = dot(n, light_dir);
    final_diffuse = (mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity));
}

void fragment() {
    // The GPU automatically interpolates v_final_diffuse across the pixels
    ALBEDO = color * final_diffuse;
}
