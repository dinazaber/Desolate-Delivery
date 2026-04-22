shader_type spatial;
render_mode unshaded, blend_mix;

uniform vec3 void_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float near_dist = 2.0; // Fully transparent at this distance
uniform float far_dist = 8.0;  // Fully black at this distance

void fragment() {
    // Get the distance from the camera to the doorway
    float dist = distance(CAMERA_POSITION_WORLD, NODE_POSITION_WORLD);
    
    // Calculate alpha: 1.0 (black) when far, 0.0 (transparent) when near
    // The smoothstep function makes the transition feel organic
    float alpha = smoothstep(near_dist, far_dist, dist);
    
    ALBEDO = void_color;
    ALPHA = alpha;
}