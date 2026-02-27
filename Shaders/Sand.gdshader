shader_type spatial; // Using spatial for 3D world
render_mode unshaded, cull_back;

uniform vec3 sand_color : source_color = vec3(0.76, 0.65, 0.5);
uniform sampler2D noise_tex : source_color, filter_nearest;
uniform vec2 speed = vec2(0.05, 0.02);

// Accessing the depth buffer for proximity fade

void fragment() {
    // 1. Animate UVs for the "Wind" effect
    vec2 moving_uv = UV + (speed * TIME);
    float noise_val = texture(noise_tex, moving_uv).r;

    // 2. Proximity Fade (Soft edges against objects)


    // 3. Distance Fade (Soft edges near camera)


    // 4. Combine everything
    ALBEDO = sand_color;
    // We use the noise multiplied by our density and the two fades
    ALPHA = noise_val;
}