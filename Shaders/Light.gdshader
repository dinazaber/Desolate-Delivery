shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 base_color: source_color = vec3(1.0, 1.0, 1.0);
uniform float facet_intensity : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    vec3 flat_normal = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
   
    float fake_light = flat_normal.y * 0.2 + flat_normal.z * 0.1;
    
    vec3 final_color = base_color + (fake_light * facet_intensity);
	
	float fresnel = 0.6 - dot(flat_normal, VIEW);

	ALBEDO = final_color - (fresnel * 0.15);
}
