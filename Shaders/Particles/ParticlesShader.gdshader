// Shader for particles

shader_type spatial;
render_mode shadows_disabled, cull_disabled;

group_uniforms Adjustments;
uniform vec4 color: source_color;
uniform bool enable_glow = false;
uniform float glow_intensity = 1.0;

void fragment() {
    ALBEDO = color.rgb;
	ALPHA = color.a;
	if (enable_glow) EMISSION = color.rgb * glow_intensity;
}
