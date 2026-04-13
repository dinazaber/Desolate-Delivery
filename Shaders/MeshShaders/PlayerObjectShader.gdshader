shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform sampler2D mask_palette : filter_nearest;
uniform sampler2D roughness_map : filter_nearest; 

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
uniform float facet_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float specular_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float shininess : hint_range(1.0, 100.0) = 32.0;

// Update this via GDScript with the Sun's Global Position
uniform vec3 sun_position; 

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
    // Pass World Position and World Normal to Fragment
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
    vec3 color = vec3(0,0,0);
    float spec_mask = texture(roughness_map, UV).r;

    // 1. Calculate the Dynamic Light Direction based on Position
    // This points from the Object surface to the Sun
    vec3 light_dir = normalize(sun_position - v_world_pos);
    
    // 2. Calculate View Direction in World Space
    // (CAMERA_BASE_MATRIX[3].xyz is the world camera position)
    vec3 view_dir = normalize(CAMERA_POSITION_WORLD - v_world_pos);

    // --- DYNAMIC DIFFUSE (Facet Lighting) ---
    // Uses the world-space normal (which accounts for object rotation)
    float lum = dot(v_world_normal, light_dir);
    float shadow_factor = clamp(lum, 0.0, 1.0);
    float final_diffuse = mix(1.0, shadow_factor, facet_intensity);

    // --- DYNAMIC SPECULAR (Blinn-Phong) ---
    vec3 half_v = normalize(light_dir + view_dir);
    float spec_dot = pow(max(dot(v_world_normal, half_v), 0.0), shininess);
    vec3 specular = vec3(1.0) * spec_dot * spec_mask * specular_intensity;

    ALBEDO = (color * final_diffuse) + specular;
}