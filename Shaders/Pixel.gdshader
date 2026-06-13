shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
// Drag and drop your SubViewport texture into this slot via the Inspector
uniform sampler2D mask_texture : filter_nearest; 

uniform float pixel_size : hint_range(10.0, 500.0) = 128.0;

void fragment() {
    // 1. Grab the normal screen pixel color
    vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // 2. Read the black-and-white mask texture
    float mask_value = texture(mask_texture, SCREEN_UV).r;
    
    // 3. Calculate pixelated screen-space coordinates
    vec2 blocky_uv = round(SCREEN_UV * pixel_size) / pixel_size;
    vec4 pixelated_color = texture(SCREEN_TEXTURE, blocky_uv);
    
    // 4. Mix them! If mask is white (> 0.5), use pixelated. Otherwise, keep original.
    if (mask_value > 0.5) {
        COLOR = pixelated_color;
    } else {
        COLOR = original_color;
    }
}