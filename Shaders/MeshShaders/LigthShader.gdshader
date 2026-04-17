// Use this shader on objects that don't use detail textures at all

shader_type spatial;
render_mode unshaded, cull_disabled;

group_uniforms Adjustments;
uniform vec3 color: source_color;
uniform float light_x = 0.5;
uniform float light_y = 0.5;
uniform float light_z = 0.5;
uniform float facet_intensity = 0.5;

varying vec3 worldPos;
varying vec3 world_normal;


void vertex(){
    worldPos = VERTEX;
    world_normal = NORMAL;   
}

void fragment() {
    vec3 n = normalize(world_normal);
    
    // --- LIGHTING ---
    vec3 light_dir = normalize(vec3(light_x, light_y, light_z));
    float lum = dot(n, light_dir);
    float final_diffuse = mix(1.0, clamp(lum, 0.0, 1.0), facet_intensity);
	
    ALBEDO = color * final_diffuse;
}
