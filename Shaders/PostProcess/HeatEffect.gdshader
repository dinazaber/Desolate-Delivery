shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, fog_disabled;

// Switched screen_texture to filter_nearest to stop bilinear edge bleeding
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D noise_texture : repeat_enable, filter_linear;

uniform float distortion_strength : hint_range(0.0, 0.02) = 0.004;
uniform float distortion_speed : hint_range(0.0, 5.0) = 1.2;
uniform float start_distance : hint_range(0.0, 100.0) = 20.0;
uniform float max_distance : hint_range(10.0, 300.0) = 80.0;
uniform float edge_threshold : hint_range(0.05, 5.0) = 0.5;

float get_linear_depth(vec2 uv, mat4 inv_proj) {
    float raw_depth = texture(depth_texture, uv).r;
    vec4 view_pos = inv_proj * vec4(uv * 2.0 - 1.0, raw_depth, 1.0);
    return -view_pos.z / view_pos.w;
}

void fragment() {
    float current_depth = get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
    float mask = clamp((current_depth - start_distance) / (max_distance - start_distance), 0.0, 1.0);

    // Compute local depth slope (detect thin geometric edges)
    float depth_dx = dFdx(current_depth);
    float depth_dy = dFdy(current_depth);
    float edge_delta = length(vec2(depth_dx, depth_dy));

    vec2 noise_uv = UV + vec2(0.0, TIME * distortion_speed * 0.05);
    vec2 noise_vec = texture(noise_texture, noise_uv).rg - vec2(0.5);
    vec2 offset = noise_vec * distortion_strength * mask;

    float offset_depth = get_linear_depth(SCREEN_UV + offset, INV_PROJECTION_MATRIX);

    // Reject distortion on thin silhouettes or large depth jumps
    if (edge_delta > edge_threshold || abs(current_depth - offset_depth) > edge_threshold) {
        ALBEDO = texture(screen_texture, SCREEN_UV).rgb;
    } else {
        ALBEDO = texture(screen_texture, SCREEN_UV + offset).rgb;
    }
}