shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 albedo : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 wire_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);

// Width in pixels (stays constant regardless of face size)
uniform float wire_pixel_width : hint_range(0.0, 5.0) = 1.0; 
// How much the line thins out in the distance (0.0 = constant pixels, 1.0 = full perspective)
uniform float perspective_factor : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 uv = UV;
    
    // 1. Distance to UV boundaries
    vec2 dist_to_edge = min(uv, 1.0 - uv);
    
    // 2. The Screen-Space Derivative (Pixel thickness)
    vec2 derivative = fwidth(uv);
    
    // 3. THE HYBRID FIX:
    // 'VERTEX.z' is the distance from the camera in view space.
    // We use this to "counter-scale" the derivative.
    float depth_scale = mix(1.0, abs(VERTEX.z) * 0.1, perspective_factor);
    vec2 adjusted_derivative = derivative * depth_scale;
    
    // 4. Calculate pixel distance with depth compensation
    vec2 pixel_dist = dist_to_edge / adjusted_derivative;
    float closest_pixel_edge = min(pixel_dist.x, pixel_dist.y);
    
    // 5. Create the mask
    float wire_mask = 1.0 - smoothstep(wire_pixel_width, wire_pixel_width + 1.0, closest_pixel_edge);
    
    // 6. Overshoot Protection
    if (uv.x < -0.01 || uv.x > 1.01 || uv.y < -0.01 || uv.y > 1.01) {
        wire_mask = 0.0;
    }

    ALBEDO = mix(albedo.rgb, wire_color.rgb, wire_mask);
}