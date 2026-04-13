shader_type spatial;

uniform float gradient_height : hint_range(0.01, 2.0) = 1.0;
uniform float alpha_strength : hint_range(0.0, 1.0) = 1.0;
uniform float black_power : hint_range(1.0, 5.0) = 2.0;

void fragment() {
    float gradient = clamp(UV.y / gradient_height, 0.0, 1.0);

    gradient = pow(gradient, black_power);

    float alpha = (1.0 - gradient) * alpha_strength;

    ALBEDO = vec3(0.0);
    ALPHA = alpha;
}


