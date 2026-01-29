shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 out_color: source_color = vec4(0.0, 0.2, 1.0, 1.0);
uniform float amount: hint_range(0.1, 2.0) = 0.5;
uniform float fps_limit: hint_range(0.1, 60.0) = 5.0; 

float get_wave_height(vec2 pos, float time) {
    vec2 grid_pos = floor(pos * 2.0);
    float h = sin(grid_pos.x * 0.5 + time) * cos(grid_pos.y * 0.5 + time);
    return h * amount;
}

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    float stepped_time = floor(TIME * fps_limit) / fps_limit;

    float y_offset = get_wave_height(world_pos.xz, stepped_time);
    VERTEX.y += y_offset;
}

void fragment() {
    vec3 flat_normal = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
    vec3 final_color = out_color.rgb;
    float fresnel = pow(1.0 - dot(flat_normal, VIEW), 3.0);

    ALBEDO = mix(final_color, vec3(1.0), fresnel * 0.3);
}