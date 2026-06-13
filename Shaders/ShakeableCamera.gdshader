shader_type canvas_item;

// Allows you to sample the screen for post-processing
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// The number of color levels per channel (Red, Green, Blue)
uniform float levels : hint_range(2.0, 20.0) = 4.0;

void fragment() {
    // 1. Get the original color from the screen texture
    vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // 2. Separate RGB channels to process them
    vec3 color = original_color.rgb;
    
    // 3. Mathematical posterization: 
    // Multiply by levels, round to whole numbers, then divide back down
    color = floor(color * levels) / (levels - 1.0);
    
    // 4. Clamp the output to keep it in a safe 0.0 - 1.0 range
    color = clamp(color, 0.0, 1.0);
    
    // 5. Output the color while keeping the original alpha channel
    COLOR = vec4(color, original_color.a);
}