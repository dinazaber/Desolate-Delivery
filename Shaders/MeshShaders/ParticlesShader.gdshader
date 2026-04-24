// Shader for particles

shader_type spatial;
render_mode unshaded, shadows_disabled;

group_uniforms Adjustments;
uniform vec4 color: source_color;

void fragment() {
    ALBEDO = color.rgb;
	ALPHA = color.a;
}
