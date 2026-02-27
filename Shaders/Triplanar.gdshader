shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D albedo_texture : source_color;

// Controls for each axis
uniform vec3 texture_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 texture_offset = vec3(0.0, 0.0, 0.0);
uniform vec3 texture_rotation = vec3(0.0, 0.0, 0.0); // In degrees

// --- NEW UNIFORM ---
uniform float triplanar_sharpness : hint_range(0.1, 20) = 2.0;

vec2 rotate_uv(vec2 uv, float rotation) {
    float mid = 0.5;
    float r = radians(rotation);
    return vec2(
        cos(r) * (uv.x - mid) + sin(r) * (uv.y - mid) + mid,
        cos(r) * (uv.y - mid) - sin(r) * (uv.x - mid) + mid
    );
}

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
    local_pos = VERTEX;
    local_normal = abs(NORMAL); 
}

void fragment() {
    vec3 n = local_normal;
    vec3 p = local_pos;

    // 1. Sharpen the normals
    // Raising to a power makes the dominant axis much stronger than the others.
    vec3 weights = pow(n, vec3(triplanar_sharpness));
    
    // 2. Normalize weights so they sum to 1.0
    weights /= (weights.x + weights.y + weights.z + 0.0001);

    // 3. Calculate UVs (Same as before)
    vec2 uv_x = (p.zy * texture_scale.x) + texture_offset.x;
    vec2 uv_y = (p.xz * texture_scale.y) + texture_offset.y;
    vec2 uv_z = (p.xy * texture_scale.z) + texture_offset.z;

    uv_x = rotate_uv(uv_x, texture_rotation.x);
    uv_y = rotate_uv(uv_y, texture_rotation.y);
    uv_z = rotate_uv(uv_z, texture_rotation.z);

    // 4. Sample and Blend
    vec3 tex_x = texture(albedo_texture, uv_x).rgb;
    vec3 tex_y = texture(albedo_texture, uv_y).rgb;
    vec3 tex_z = texture(albedo_texture, uv_z).rgb;

    ALBEDO = tex_x * weights.x + tex_y * weights.y + tex_z * weights.z;
}
