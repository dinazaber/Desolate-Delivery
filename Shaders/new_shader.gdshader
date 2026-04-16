shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform vec4 albedo : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 wire_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float wire_width : hint_range(0.0, 0.2) = 0.01; // Width in meters

void fragment() {
    vec2 uv = UV;
    
    // 1. Distance to edge in UV space
    vec2 dist_to_edge = min(uv, 1.0 - uv);
    
    // 2. Get the screen-space change of UVs
    vec2 d_uv = fwidth(uv);
    
    // 3. THE FIX: Pixel-to-World Scale
    // We calculate how many meters are in one screen pixel at this depth
    // This is mathematically more stable than comparing UV-to-Vertex directly
    float pixel_to_meter = length(fwidth(VERTEX));
    
    // 4. Convert UV distance to Meters
    // We divide UV distance by (UV-per-pixel) to get pixels, 
    // then multiply by (Meters-per-pixel) to get meters.
    vec2 dist_in_meters = (dist_to_edge / max(d_uv, 0.0001)) * pixel_to_meter;
    float closest_dist = min(dist_in_meters.x, dist_in_meters.y);
    
    // 5. Create the crisp mask
    // We use a tiny 0.001 transition for anti-aliasing
    float wire_mask = 1.0 - smoothstep(wire_width, wire_width + 0.002, closest_dist);
    
    ALBEDO = mix(albedo.rgb, wire_color.rgb, wire_mask);
}