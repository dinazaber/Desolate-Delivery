// Shader for particles

shader_type spatial;
render_mode unshaded, shadows_disabled;

group_uniforms Adjustments;
uniform vec3 color: source_color;

void fragment() {
    ALBEDO = color;
}
