shader_type spatial;
render_mode unshaded;

uniform vec4 wall_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform float room_depth : hint_range(0.1, 10.0) = 1.0;
// Set this to the scale of your plane!
uniform vec2 mesh_scale = vec2(1.0, 1.0); 

void fragment() {
    // 1. Get the View Direction in Local Space
    // This part from your first shader is perfect for perspective
    vec3 rd = (vec4(normalize(VIEW), 0.0) * VIEW_MATRIX).xyz;
    rd = (vec4(rd, 0.0) * inverse(MODEL_MATRIX)).xyz;
    rd = normalize(rd);

    // 2. Adjust for Mesh Scale
    // We scale the UVs and the Ray Direction to match the actual plane size
    vec2 uv = (UV * 2.0 - 1.0) * mesh_scale;
    vec3 ray_origin = vec3(uv, 0.0);
    
    // We also need to scale the ray direction's components
    // If the mesh is wide, the X-component of the ray needs to be "slower"
    vec3 ray_dir = rd; 

    // 3. Ray-Box Intersection
    // We define the box boundaries: 
    // X from -mesh_scale.x to +mesh_scale.x
    // Y from -mesh_scale.y to +mesh_scale.y
    // Z from 0 to -room_depth
    vec3 inv_rd = 1.0 / ray_dir;
    
    // Distances to the 6 planes of the room
    vec3 t0 = (vec3(-mesh_scale, -room_depth) - ray_origin) * inv_rd;
    vec3 t1 = (vec3( mesh_scale, 0.01) - ray_origin) * inv_rd;
    
    // Find the intersection distance (the nearest wall in front of us)
    vec3 t_max = max(t0, t1);
    float t = min(t_max.x, min(t_max.y, t_max.z));
    
    // 4. Calculate hit position
    vec3 hit_pos = ray_origin + ray_dir * t;
    
    // 5. Shading logic
    // Calculate how far back the hit is for the fade effect
    float depth_fade = clamp(abs(hit_pos.z) / room_depth, 0.0, 1.0);
    
    // Visual Polish: Identify which wall we hit for better shading
    vec3 color = wall_color.rgb;
    
    // Check if we hit the floor/ceiling (Y walls)
    if (abs(hit_pos.y) > mesh_scale.y - 0.01) {
        color *= 0.6; // Floor/Ceiling darker
    }
    // Check if we hit the side walls (X walls)
    else if (abs(hit_pos.x) > mesh_scale.x - 0.01) {
        color *= 0.8; // Sides medium
    }
    // Otherwise we hit the back wall
    else {
        color *= 0.4; // Back wall darkest
    }

    ALBEDO = mix(color, vec3(0.0), depth_fade * 0.5);
}