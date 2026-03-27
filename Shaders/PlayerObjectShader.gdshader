shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform sampler2D albedo : source_color, filter_nearest; 
uniform sampler2D roughness_map : filter_nearest; 

uniform float facet_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float specular_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float shininess : hint_range(1.0, 100.0) = 32.0;

// This will be updated by the GDScript
uniform vec3 sun_direction; 

void fragment() {
    vec3 color = texture(albedo, UV).rgb;
    float spec_mask = texture(roughness_map, UV2).r;

    // World Space Normals and View Dir
    vec3 world_normal = normalize(mat3(INV_VIEW_MATRIX) * NORMAL);
    vec3 world_view_dir = normalize(CAMERA_POSITION_WORLD - NODE_POSITION_WORLD);

    // --- DYNAMIC SUN LIGHTING ---
    // Using the actual sun direction from the scene
    float lum = dot(world_normal, sun_direction);
    float shadow_factor = clamp(lum, 0.0, 1.0);
    float final_diffuse = mix(1.0, shadow_factor, facet_intensity);

    // --- DYNAMIC SPECULAR ---
    vec3 half_v = normalize(sun_direction + world_view_dir);
    float spec_dot = pow(max(dot(world_normal, half_v), 0.0), shininess);
    vec3 specular = vec3(1.0) * spec_dot * spec_mask * specular_intensity;

    ALBEDO = (color * final_diffuse) + specular;
}