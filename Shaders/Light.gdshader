shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D albedo : source_color, filter_nearest; 
// Your 4x4 Roughness/Specular map assigned to UV2
uniform sampler2D roughness_map : filter_nearest; 

uniform float facet_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float specular_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float shininess : hint_range(1.0, 100.0) = 32.0;

// Light direction controls
uniform float x : hint_range(-1.0, 1.0) = 0.5;
uniform float y : hint_range(-1.0, 1.0) = 0.5;
uniform float z : hint_range(-1.0, 1.0) = 0.5;

void fragment() {
    vec3 color = texture(albedo, UV).rgb;
    
    // Sample the 4x4 texture from UV2
    // We only need one channel (r) to determine "how much" specular to apply
    float spec_mask = texture(roughness_map, UV2).r;

    vec3 n = normalize(NORMAL);
    vec3 light_dir = normalize(vec3(x, y, z));
    vec3 view_dir = normalize(VIEW); // Direction from pixel to camera

    // --- DIFFUSE (Your existing logic) ---
    float lum = dot(n, light_dir);
    float shadow_factor = clamp(lum, 0.0, 1.0);
    float final_diffuse = mix(1.0, shadow_factor, facet_intensity);

    // --- SPECULAR (The "Shiny" Logic) ---
    // Half-vector approach for Blinn-Phong specular
    vec3 half_v = normalize(light_dir + view_dir);
    float spec_dot = pow(max(dot(n, half_v), 0.0), shininess);
    
    // Multiply specular by the mask from UV2
    vec3 specular = vec3(1.0) * spec_dot * spec_mask * specular_intensity;

    // Combine: (Base Color * Light) + Shiny Highlights
    ALBEDO = (color * final_diffuse) + specular;
}
