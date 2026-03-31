shader_type spatial;
render_mode unshaded;

// 10 Individual Uniforms
uniform sampler2D tex1 : source_color, filter_nearest;
uniform sampler2D tex2 : source_color, filter_nearest;
uniform sampler2D tex3 : source_color, filter_nearest;
uniform sampler2D tex4 : source_color, filter_nearest;
uniform sampler2D tex5 : source_color, filter_nearest;
uniform sampler2D tex6 : source_color, filter_nearest;
uniform sampler2D tex7 : source_color, filter_nearest;
uniform sampler2D tex8 : source_color, filter_nearest;
uniform sampler2D tex9 : source_color, filter_nearest;
uniform sampler2D tex10 : source_color, filter_nearest;

uniform float triplanar_sharpness = 8.0;
uniform float uv_scale = 1.0;

varying vec3 worldPos;
varying vec3 world_normal;

// Helper function for Triplanar mapping a single texture
vec3 get_triplanar(sampler2D p_sampler, vec3 p_weights, vec3 p_pos) {
	vec3 samp = vec3(0.0);
	samp += texture(p_sampler, p_pos.xy).rgb * p_weights.z;
	samp += texture(p_sampler, p_pos.xz).rgb * p_weights.y;
	samp += texture(p_sampler, p_pos.zy).rgb * p_weights.x;
	return samp;
}

void vertex(){
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	// 1. Setup Triplanar Coordinates
	vec3 weights = pow(abs(normalize(world_normal)), vec3(triplanar_sharpness));
	weights /= (weights.x + weights.y + weights.z);
	// World-space position for seamless mapping across objects
	vec3 world_pos = worldPos * uv_scale;

	// 2. Identify the Vertex Color (The "ID")
	vec3 c = COLOR.rgb;

	// 3. Create Masks (Checking for specific color matches)
	// We use distance() to allow for tiny rounding errors in color
	float m1 = step(distance(c, vec3(1,0,0)), 0.1); // Red
	float m2 = step(distance(c, vec3(0,1,0)), 0.1); // Green
	float m3 = step(distance(c, vec3(0,0,1)), 0.1); // Blue
	float m4 = step(distance(c, vec3(1,1,0)), 0.1); // Yellow
	float m5 = step(distance(c, vec3(1,0,1)), 0.1); // Magenta
	float m6 = step(distance(c, vec3(0,1,1)), 0.1); // Cyan
	float m7 = step(distance(c, vec3(1,1,1)), 0.1); // White
	float m8 = step(distance(c, vec3(1,0.5,0)), 0.1); // Orange
	float m9 = step(distance(c, vec3(0.5,0,1)), 0.1); // Purple
	float m10 = step(distance(c, vec3(0.5,0.5,0.5)), 0.1); // Grey

	// 4. Sample textures only if their mask is active
	// Note: We multiply by mask so inactive textures contribute 0
	vec3 out_color = vec3(0.0);
	if (m1 > 0.5) out_color = get_triplanar(tex1, weights, world_pos);
	else if (m2 > 0.5) out_color = get_triplanar(tex2, weights, world_pos);
	else if (m3 > 0.5) out_color = get_triplanar(tex3, weights, world_pos);
	else if (m4 > 0.5) out_color = get_triplanar(tex4, weights, world_pos);
	else if (m5 > 0.5) out_color = get_triplanar(tex5, weights, world_pos);
	else if (m6 > 0.5) out_color = get_triplanar(tex6, weights, world_pos);
	else if (m7 > 0.5) out_color = get_triplanar(tex7, weights, world_pos);
	else if (m8 > 0.5) out_color = get_triplanar(tex8, weights, world_pos);
	else if (m9 > 0.5) out_color = get_triplanar(tex9, weights, world_pos);
	else if (m10 > 0.5) out_color = get_triplanar(tex10, weights, world_pos);
	else out_color = c; // FALLBACK: Use Vertex Color if no match

	ALBEDO = out_color;
}