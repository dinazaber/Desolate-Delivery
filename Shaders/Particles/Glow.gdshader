shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded, shadows_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.9, 0.4, 1.0); // Yellow
uniform vec4 glow_color : source_color = vec4(1.0, 0.3, 0.0, 1.0); // Orange

uniform float core_power : hint_range(0.1, 10.0) = 2.5;           // Higher = tighter yellow center
uniform float glow_power : hint_range(0.1, 10.0) = 1.0;           // Lower = wider orange aura
uniform float alpha_multiplier : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    // Base alignment from center (1.0) to edge (0.0)
    float center_distance = dot(normalize(NORMAL), normalize(VIEW));
    
    // Calculate the two distinct fading layers in math
    float core_fade = pow(center_distance, core_power);
    float glow_fade = pow(center_distance, glow_power);
    
    // Layer the colors: core sits on top of the wider glow
    vec3 final_color = mix(glow_color.rgb, core_color.rgb, core_fade);
    
    ALBEDO = final_color;
    
    // The alpha handles the smooth outside fade of the entire object
    // using the wider glow's falloff profile
    ALPHA = glow_fade * alpha_multiplier;
}