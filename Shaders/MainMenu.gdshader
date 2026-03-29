shader_type canvas_item;

// Noise Textures
uniform sampler2D noise_img_fast : repeat_enable, filter_linear;
uniform sampler2D noise_img_slow : repeat_enable, filter_linear;

uniform vec4 dust_color : source_color = vec4(0.8, 0.7, 0.5, 0.5);
uniform float total_opacity : hint_range(0.0, 1.0) = 0.5;

// Speeds
uniform vec2 speed_fast = vec2(0.1, 0.02);
uniform vec2 speed_slow = vec2(0.04, -0.01);

uniform float look_angle_factor : hint_range(0.0, 1.0);

// Density settings
uniform float density_fast = 1.0;
uniform float density_slow = 2.5;

void fragment() {
    vec2 uv_fast = UV * density_fast + (TIME * speed_fast);
    vec2 uv_slow = UV * density_slow + (TIME * speed_slow);

    float n_fast = texture(noise_img_fast, uv_fast).r;
    float n_slow = texture(noise_img_slow, uv_slow).r;
	
    float final_noise = (n_fast * n_fast) * n_slow;

    final_noise = smoothstep(0.1, 0.6, final_noise);

    vec4 final_color = dust_color;
    final_color.a *= final_noise * total_opacity * look_angle_factor;

    COLOR = final_color;
}