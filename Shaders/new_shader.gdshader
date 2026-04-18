shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 albedo : source_color = vec3(0.1, 0.1, 0.1);
uniform vec3 wire_color : source_color = vec3(0.0, 1.0, 1.0);

// Width in pixels (stays constant regardless of face size)
uniform float wire_width : hint_range(0.0, 5.0) = 1.0; 
// How much the line thins out in the distance (0.0 = constant pixels, 1.0 = full perspective)
uniform float perspective_factor : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 uv = UV;

    

    // Distance to edge in UV space

    vec2 dist_to_edge = min(uv, 1.0 - uv);

    

    // Get the screen-space change of UVs

    vec2 d_uv = fwidth(uv);

    

    // We calculate how many meters are in one screen pixel at this depth

    // This is mathematically more stable than comparing UV-to-Vertex directly

    float pixel_to_meter = length(fwidth(VERTEX));

    

    // Convert UV distance to Meters

    // We divide UV distance by (UV-per-pixel) to get pixels, 

    // then multiply by (Meters-per-pixel) to get meters.

    vec2 dist_in_meters = (dist_to_edge / max(d_uv, 0.0001)) * pixel_to_meter;

    float closest_dist = min(dist_in_meters.x, dist_in_meters.y);

    

    // Create the crisp mask

    float wire_mask = 1.0 - smoothstep(wire_width, wire_width + 0.002, closest_dist);
	ALBEDO = mix(albedo, wire_color, wire_mask);
}