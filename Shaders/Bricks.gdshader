shader_type spatial;
render_mode cull_disabled;

uniform vec3 mortar_color : source_color = vec3(1.0, 1.0, 1.0);


uniform float brick_width  = 1.0;
uniform float brick_height = 0.5;
uniform float row_offset   = 0.5;


uniform float mortar_size = 0.05;

void fragment() {
    vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;


    float row = floor(wp.z / brick_height);
    float offset_amount = mod(row, 2.0) * row_offset * brick_width;

    float bx = wp.x + offset_amount;
    float bz = wp.z;

    float cx = fract(bx / brick_width);
    float cz = fract(bz / brick_height);

    float msx = mortar_size;
    float msz = mortar_size;

    bool is_mortar =
        cx < msx || cz < msz ||
        cx > (1.0 - msx) ||
        cz > (1.0 - msz);

    if (is_mortar) {
        ALBEDO = mortar_color;
        ALPHA = 1.0;
    } else {
        ALPHA = 0.0;
    }
}





