shader_type spatial;

render_mode cull_disabled;

group_uniforms textures;
uniform sampler2D flag_texture: source_color, filter_linear;
uniform sampler2D detail_texture: source_color, filter_linear;
uniform float detail_scale = 1.0;
uniform float detail_alpha = 1.0;

group_uniforms flag_settings;
uniform float speed = 2.0;
uniform float frequency_y = 5.0;
uniform float frequency_x = 2.5;
uniform float frequency_z = 2.5;
uniform float amplitude_y = 0.1;
uniform float amplitude_x = 0.05;
uniform float amplitude_z = 0.05;
uniform float inclination = -0.0;

varying vec2 project_uv;

void fragment(){
	vec4 albedo_tex = texture(flag_texture, UV);
	vec4 detail_tex = texture(detail_texture, project_uv);
	ALBEDO = mix(albedo_tex.rgb, detail_tex.rgb, detail_tex.a * detail_alpha);
}

void vertex(){
	
	vec2 det_s = vec2(detail_scale, detail_scale);
	project_uv = VERTEX.xz * det_s;
	
	VERTEX.y += sin((UV.x - TIME * speed) * frequency_y) * amplitude_y * UV.x;
	VERTEX.x += cos((UV.y - TIME * speed) * frequency_x) * amplitude_x * 0.1 * UV.x;
	VERTEX.z += sin((UV.x - TIME * speed) * frequency_z) * amplitude_z * UV.x;
	VERTEX.x -= (1.0 - UV.y) * inclination;
	

}