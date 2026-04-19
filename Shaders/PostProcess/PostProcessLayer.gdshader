shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    vec4 tex = texture(screen_texture, SCREEN_UV);
    vec3 color = tex.rgb;

    // 1. Apply Brightness
    color = color * brightness;

    // 2. Apply Contrast
    // Uses 0.5 as the pivot point to push colors toward black or white
    color = (color - 0.5) * contrast + 0.5;

    // 3. Apply Saturation
    // Uses the luminance coefficients for "true" grayscale conversion
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(luminance), color, saturation);

    COLOR = vec4(color, tex.a);
}
