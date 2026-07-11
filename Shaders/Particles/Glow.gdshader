shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded;

uniform vec4 shine_color : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform float fade_power : hint_range(0.1, 10.0) = 2.0;              // Higher = tighter core, softer edge
uniform float alpha_multiplier : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    // High value when looking directly at the center, drops to 0.0 at the grazing edges
    float center_glow = dot(normalize(NORMAL), normalize(VIEW));
    
    // Smooth out the falloff toward the edges
    float smooth_fade = pow(center_glow, fade_power);
    
    ALBEDO = shine_color.rgb;
    ALPHA = smooth_fade * shine_color.a * alpha_multiplier;
}