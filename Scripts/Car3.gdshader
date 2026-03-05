shader_type spatial;

render_mode cull_disabled;

uniform vec3 albedo : source_color = vec3(0.2, 0.4, 0.1); // Your Green

void fragment() {
    ALBEDO = albedo;
}

void light() {
    // This is the "Half-Lambert" trick
    // Instead of light going from 1 to 0, it goes from 1 to 0.5
    float dot_product = dot(NORMAL, LIGHT);
    float half_lambert = dot_product * 0.5 + 0.5;
    
    // Mix the sun color with a "shadow color" (like a deep blue/purple)
    vec3 shadow_color = vec3(0.1, 0.1, 0.3); 
    vec3 light_final = mix(shadow_color, LIGHT_COLOR, half_lambert);
    
    DIFFUSE_LIGHT += light_final * ATTENUATION * ALBEDO;
}
