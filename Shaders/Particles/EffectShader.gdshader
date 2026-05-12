// Shader for particles

shader_type spatial;
render_mode shadows_disabled, cull_disabled;

group_uniforms Adjustments;
uniform sampler2D albedo: source_color, filter_linear;
uniform bool enable_glow = false;
uniform float glow_intensity = 1.0;
uniform bool billboard = false;
uniform bool draw_forward = false;

void fragment() {
    vec4 tex = texture(albedo, UV);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	if (enable_glow) EMISSION = tex.rgb * glow_intensity;
}

void vertex() {
	// Grab the scale from the model matrix
	
	if (draw_forward){
		POSITION = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);
	    POSITION.z = mix(POSITION.z, POSITION.w, 0.9);
	}
}
