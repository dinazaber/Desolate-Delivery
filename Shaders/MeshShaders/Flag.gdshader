shader_type spatial;

render_mode unshaded,cull_disabled;

uniform float speed = 2.0;
uniform float frequency_y = 5.0;
uniform float frequency_x = 2.5;
uniform float frequency_z = 2.5;
uniform float amplitude_y = 0.1;
uniform float amplitude_x = 0.05;
uniform float amplitude_z = 0.05;
uniform float inclination = -0.04;

uniform sampler2D color: source_color, filter_nearest;

void fragment(){
	vec4 albedo_tex = texture(color, UV);
	ALBEDO = vec3(1.0) * albedo_tex.rgb;
	ALPHA = albedo_tex.a;
}

void vertex(){
	VERTEX.y += sin((UV.x - TIME * speed) * frequency_y) * amplitude_y * UV.x;
	VERTEX.x += cos((UV.y - TIME * speed) * frequency_x) * amplitude_x * 0.1 * UV.x;
	VERTEX.z += sin((UV.x - TIME * speed) * frequency_z) * amplitude_z * UV.x;
	VERTEX.x -= (1.0 - UV.y) * inclination;
}