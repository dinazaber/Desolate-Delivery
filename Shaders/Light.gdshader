shader_type spatial;
// blend_mul makes this pass multiply against the pixels already on screen
render_mode unshaded, cull_disabled, blend_mul;

uniform float facet_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float x : hint_range(0.0, 1.0) = 0.5;
uniform float y : hint_range(0.0, 1.0) = 0.5;
uniform float z : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // 1. Calculate the flat normal
    vec3 flat_normal = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));

    // 2. Simple top-down light influence (1.0 is neutral, lower is darker)
    // We bias this so it mostly darkens the "shadow" sides
	vec3 light_dir = normalize(vec3(x, y, z));
    float lum = dot(flat_normal, light_dir);

    // 3. Control how much darkening happens
    // Result of 1.0 means "no change", lower means "darker"
    float shadow_factor = mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity);

    // 4. Apply to ALBEDO
    // Because of blend_mul, white (1,1,1) is invisible, and black (0,0,0) is total darkness
    ALBEDO = vec3(shadow_factor);
}
