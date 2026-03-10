shader_type spatial;

render_mode unshaded ,cull_disabled;



uniform sampler2D albedo : source_color, filter_nearest; // Color Palette

uniform float facet_intensity : hint_range(0.0, 1.0) = 0.5;



// Light direction controls

uniform float x : hint_range(-1.0, 1.0) = 0.5;

uniform float y : hint_range(-1.0, 1.0) = 0.5;

uniform float z : hint_range(-1.0, 1.0) = 0.5;



void fragment() {
	
	vec3 color = texture(albedo, UV).rgb;


    // This uses the face direction data from Blender, which treats quads as flat

    vec3 n = normalize(NORMAL);

    

    // Calculate light influence

    vec3 light_dir = normalize(vec3(x, y, z));

    float lum = dot(n, light_dir);



    // Map the light from (-1.0 to 1.0) to (0.0 to 1.0) for the shadow factor

    float shadow_factor = clamp(lum, 0.0, 1.0);

    

    // Apply intensity and mix with the base color

    // This darkens the 'back' faces without showing triangulation

    float final_diffuse = mix(1.0, shadow_factor, facet_intensity);

    

    ALBEDO = color * final_diffuse;

}
