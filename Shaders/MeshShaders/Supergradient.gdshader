shader_type spatial;
render_mode  unshaded, cull_disabled;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);

// Adjust these in the Inspector
uniform float shadow_base_y = 0.0;    // The bottom-most point of the shadow
uniform float fade_length = 1.5;      // How many meters/units the transition lasts

varying float world_y;

void vertex() {
    // Keep the position fixed to the world map
    world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
    // 1. Define the end point of our fade
    float fade_end = shadow_base_y + fade_length;

    // 2. smoothstep(edge0, edge1, x)
    // It returns 0.0 at the base and 1.0 at the top of the fade.
    float gradient = smoothstep(shadow_base_y, fade_end, world_y);

    // 3. We invert it so the shadow is at the bottom (1.0) and transparent at top (0.0)
    float mask = 1.0 - gradient;

    ALBEDO = shadow_color.rgb;
    ALPHA = mask * shadow_color.a;
}
