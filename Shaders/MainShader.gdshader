shader_type spatial;
// Note: We use default blend mode. Shader 3's 'blend_mul' is now
// handled mathematically inside the code so it only affects this object.
render_mode cull_disabled;

// --- SHADER 1: TRIPLANAR UNIFORMS ---
group_uniforms Albedo;
uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec3 texture_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 texture_offset = vec3(0.0, 0.0, 0.0);
uniform vec3 texture_rotation = vec3(0.0, 0.0, 0.0); // In degrees
uniform float triplanar_sharpness : hint_range(0.1, 16.0) = 2.0;

// --- SHADER 2: VERTICAL GRADIENT UNIFORMS ---
group_uniforms Occlusion;
const vec4 shadow_color = vec4(0.0, 0.0, 0.0, 0.6);
uniform bool enable_occlusion = true;
uniform float shadow_base_y = 0.0;
uniform float fade_length = 1.5;

// --- SHADER 3: FAKE FACET LIGHT UNIFORMS ---
group_uniforms Light;
uniform float facet_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float light_x : hint_range(-1.0, 1.0) = 0.5;
uniform float light_y : hint_range(-1.0, 1.0) = 0.5;
uniform float light_z : hint_range(-1.0, 1.0) = 0.5;


varying vec3 local_pos;
varying vec3 local_normal;
varying float world_y;

// UV Rotation Helper
vec2 rotate_uv(vec2 uv, float rotation) {
    float mid = 0.5;
    float r = radians(rotation);
    return vec2(
        cos(r) * (uv.x - mid) + sin(r) * (uv.y - mid) + mid,
        cos(r) * (uv.y - mid) - sin(r) * (uv.x - mid) + mid
    );
}

void vertex() {
    local_pos = VERTEX;
    local_normal = abs(NORMAL);
    // Transform vertex to world space for the vertical shadow
    world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
    // --- STEP 1: TRIPLANAR TEXTURING (SHADER 1) ---
    vec3 n = local_normal;
    vec3 p = local_pos;

    vec3 weights = pow(n, vec3(triplanar_sharpness));
    weights /= (weights.x + weights.y + weights.z + 0.0001);

    vec2 uv_x = (p.zy * texture_scale.x) + texture_offset.x;
    vec2 uv_y = (p.xz * texture_scale.y) + texture_offset.y;
    vec2 uv_z = (p.xy * texture_scale.z) + texture_offset.z;

    uv_x = rotate_uv(uv_x, texture_rotation.x);
    uv_y = rotate_uv(uv_y, texture_rotation.y);
    uv_z = rotate_uv(uv_z, texture_rotation.z);

    vec3 tex_x = texture(albedo_texture, uv_x).rgb;
    vec3 tex_y = texture(albedo_texture, uv_y).rgb;
    vec3 tex_z = texture(albedo_texture, uv_z).rgb;

    vec3 base_albedo = tex_x * weights.x + tex_y * weights.y + tex_z * weights.z;

    // --- STEP 2: FAKE FACET LIGHTING (SHADER 3) ---
    // Calculate flat normals for that low-poly / faceted look
    vec3 flat_normal = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
    vec3 light_dir = normalize(vec3(light_x, light_y, light_z));
    float lum = dot(flat_normal, light_dir);

    // We use the mix logic from Shader 3 to determine how much to darken
    float facet_factor = mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity);

    // Apply lighting to the textured color
    vec3 colored_with_light = base_albedo * facet_factor;

    // --- STEP 3: VERTICAL GRADIENT (SHADER 2) ---
    float fade_end = shadow_base_y + fade_length;
    float gradient = smoothstep(shadow_base_y, fade_end, world_y);
    float vertical_mask = 1.0 - gradient;
	
	if (!enable_occlusion){vertical_mask = 0.0;}

    // Blend the current color with the shadow_color based on the gradient mask
    // This mimics the "natural grounding" effect
    vec3 final_color = mix(colored_with_light, shadow_color.rgb, vertical_mask * shadow_color.a);
	final_color *= 1.3;

    // --- FINAL OUTPUT ---
    ALBEDO = final_color;
}