shader_type fog;



// Color controls

uniform vec3 albedo : source_color = vec3(0.55, 0.48, 0.38); // Desaturated sandy tone to prevent neon yellowing

uniform vec3 emission : source_color = vec3(0.0);



// Storm dynamics

uniform float density : hint_range(0.0, 10.0) = 0.05;       // Defaulted to your low target

uniform vec3 wind_direction = vec3(-1.0, -0.2, 0.5);

uniform float wind_speed = 5.0;

uniform float noise_scale = 1.5;



// Detail layering

uniform float detail_strength : hint_range(0.0, 1.0) = 0.5;



// Hash function

float hash(vec3 p) {

    p = fract(p * vec3(443.8975, 397.2973, 491.1871));

    p += dot(p.xyz, p.yzx + 19.19);

    return fract(p.x * p.y * p.z);

}



// 3D Value Noise

float noise(vec3 p) {

    vec3 i = floor(p);

    vec3 f = fract(p);

    f = f * f * (3.0 - 2.0 * f);



    return mix(

        mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),

            mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),

        mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),

            mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), 

        f.z

    );

}



// Fractional Brownian Motion

float fbm(vec3 p) {

    float value = 0.0;

    float amplitude = 0.5;

    float frequency = 1.0;

    for (int i = 0; i < 3; i++) {

        value += amplitude * noise(p * frequency);

        frequency *= 2.0;

        amplitude *= 0.5;

    }

    return value;

}



void fog() {

    // Wind movement

    vec3 time_offset = normalize(wind_direction) * TIME * wind_speed;

    vec3 sample_pos = UVW * noise_scale + time_offset;

    

    // Noise sampling

    float base_noise = fbm(sample_pos);

    vec3 micro_offset = normalize(wind_direction + vec3(0.2, 0.5, -0.1)) * TIME * (wind_speed * 1.5);

    float detail_noise = fbm(sample_pos * 2.5 + micro_offset);

    

    float final_noise = mix(base_noise, detail_noise, detail_strength);

    

    // FIX 1: Removed the harsh vertical smoothstep fade so dust spans completely top to bottom.

    // If you ever see harsh clipping at the roof of your volume, change this 1.0 to a very tight smoothstep.

    float vertical_fade = 1.0; 

    

    // Apply outputs

    DENSITY = density * final_noise * vertical_fade;

    ALBEDO = albedo;

    EMISSION = emission;

    

}