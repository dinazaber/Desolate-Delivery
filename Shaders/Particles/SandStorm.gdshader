shader_type fog;

// --- Tweakable uniforms ---
uniform vec3  sand_color     : source_color = vec3(0.91, 0.75, 0.45);
uniform vec3  horizon_color  : source_color = vec3(0.98, 0.88, 0.62);
uniform float base_density   : hint_range(0.0, 1.0)  = 0.08;
uniform float dust_height    : hint_range(0.0, 200.0) = 18.0;
uniform float horizon_falloff: hint_range(0.01, 1.0)  = 0.35;
uniform float dust_turbulence: hint_range(0.0, 4.0)   = 1.6;
uniform float time_scale     : hint_range(0.0, 1.0)   = 0.04;

// --- Simple value-noise helpers ---
float hash(vec3 p) {
    p = fract(p * vec3(127.1, 311.7, 74.7));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(mix(hash(i),               hash(i + vec3(1,0,0)), f.x),
            mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
        mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
            mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
        f.z
    );
}

float fbm(vec3 p) {
    return noise3(p)       * 0.60
         + noise3(p * 2.1) * 0.30
         + noise3(p * 4.3) * 0.10;
}

void fog() {
    vec3 drift = vec3(TIME * time_scale, 0.0, TIME * time_scale * 0.4);

    vec3 sample_pos = WORLD_POSITION * 0.012 + drift;
    float turb = fbm(sample_pos);

    float height_blend = clamp(1.0 - (WORLD_POSITION.y / dust_height), 0.0, 1.0);
    height_blend = pow(height_blend, 1.5);

    float density = base_density
                  * height_blend
                  * (1.0 + dust_turbulence * (turb - 0.5));
    density = max(density, 0.0);

    float color_t = clamp(WORLD_POSITION.y / (dust_height * 0.6), 0.0, 1.0);
    vec3  fog_col  = mix(sand_color, horizon_color, color_t);
    fog_col += vec3(0.04, 0.02, -0.01) * turb;

    ALBEDO   = fog_col;
    DENSITY  = density;
    EMISSION = fog_col * 0.15;
}