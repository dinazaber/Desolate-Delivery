shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// Replaced the local distance float with the global player position vector
global uniform vec3 player_global_position; 

// Base pixel setting (adjust to set overall retro block size)
uniform float base_pixel_size : hint_range(16.0, 512.0) = 128.0;

varying float distance_scale;

void vertex(){
	 
}

void fragment() {
    // 1. Calculate aspect ratio to keep pixels perfectly square
    vec2 aspect_ratio = vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0);
    
    // 2. NEW CALCULATION: Find the straight-line distance between 
    // the player's position vector and this object's world center
   
    distance_scale = distance(player_global_position, NODE_POSITION_WORLD);
    // Prevent division errors if the player stands exactly on the object center
    float distance_scale_final = max(distance_scale, 0.1);
    
    // 3. Scale the pixel grid dynamically using the calculated distance
    vec2 dynamic_grid = (vec2(base_pixel_size) * distance_scale_final) * aspect_ratio;
    
    // 4. Quantize the screen UVs
    vec2 blocky_uv = round(SCREEN_UV * dynamic_grid) / dynamic_grid;
    
    // 5. Output the stable pixelated background
    ALBEDO = texture(SCREEN_TEXTURE, blocky_uv).rgb;
}