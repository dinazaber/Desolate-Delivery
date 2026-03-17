shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable;
uniform float scroll_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec2 direction = vec2(1.0, 0.0);
uniform vec4 sand_color : source_color = vec4(0.8, 0.5, 0.2, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.25;
uniform float ground_start : hint_range(0.0, 1.0) = 0.5;
uniform float fade_range : hint_range(0.0, 1.0) = 0.3;
uniform float cloud_threshold : hint_range(0.0, 1.0) = 0.4;
uniform vec2 camera_position = vec2(0.0);
uniform float camera_rotation = 0.0;
uniform vec2 texture_scale = vec2(200.0);
uniform float ground_world_y : hint_range(-2000.0, 2000.0) = 400.0;  // 👈 your ground Y in world space
uniform float fade_height : hint_range(0.0, 2000.0) = 300.0;          // 👈 how far above ground it fades out

void fragment() {
    if (UV.y < ground_start) {
        COLOR = vec4(0.0);
    }

    // How far above the ground the camera is
    float height_above_ground = ground_world_y - camera_position.y;  // in Godot Y flips so this works
    
    // Fade out the whole effect as camera moves above ground level
    float height_fade = 1.0 - smoothstep(0.0, fade_height, height_above_ground);

    // Early exit if fully faded
    if (height_fade <= 0.0) {
        COLOR = vec4(0.0);
    }

    float s = sin(-camera_rotation);
    float c = cos(-camera_rotation);
    vec2 rotated_uv = vec2(
        UV.x * c - UV.y * s,
        UV.x * s + UV.y * c
    );

    vec2 world_uv = rotated_uv + camera_position / texture_scale;
    vec2 offset = normalize(direction) * TIME * scroll_speed;

    vec2 uv_large = fract(world_uv * 2.0 + offset);
    float noise_large = texture(noise_tex, uv_large).r;

    vec2 uv_small = fract(world_uv * 5.0 + offset * 1.3);
    float noise_small = texture(noise_tex, uv_small).r;

    float combined = noise_large * noise_small;
    float clouds = smoothstep(cloud_threshold, cloud_threshold + 0.3, combined);
    float fade = smoothstep(0.0, fade_range, UV.y - ground_start);

    COLOR = vec4(sand_color.rgb, clouds * opacity * fade * height_fade);
}