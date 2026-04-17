// Use this shader on objects that don't use detail textures at all

shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

group_uniforms Wireframe;
uniform vec4 wire_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float wire_width : hint_range(0.0, 0.2) = 0.01; // Width in meters
uniform float wire_transparency : hint_range(0.0, 1.0) = 1.0;

group_uniforms Adjustments;
uniform vec3 color: source_color;
uniform float light_x = 0.5;
uniform float light_y = 0.5;
uniform float light_z = 0.5;
uniform float facet_intensity = 0.5;

varying vec3 worldPos;
varying vec3 world_normal;


void vertex(){
    worldPos = VERTEX;
    world_normal = NORMAL;   
}

void fragment() {
    vec3 n = normalize(world_normal);
    
    // --- LIGHTING ---
    vec3 light_dir = normalize(vec3(light_x, light_y, light_z));
    float lum = dot(n, light_dir);
    float final_diffuse = mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity);
	
	// --- WIREFRAME ---
	
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
    // We use a tiny 0.001 transition for anti-aliasing
    float wire_mask = 1.0 - smoothstep(wire_width, wire_width + 0.002, closest_dist);
	
	vec3 blended_wire = mix(color * final_diffuse, wire_color.rgb, wire_transparency);
	
    ALBEDO = mix(color * final_diffuse, blended_wire, wire_mask);
}
