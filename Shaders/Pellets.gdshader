shader_type particles;

// Array to hold our hit positions (adjust size to your pellet count)
uniform vec3 hit_points[20]; 
uniform vec3 gun_barrel_pos;
uniform float speed = 100;

void start() {
    // INDEX is the particle ID (0, 1, 2...)
    // We grab the specific hit point for this particle
    vec3 target = hit_points[INDEX];
    
    
    // Calculate direction and distance
    vec3 dir = target - gun_barrel_pos;
	
	TRANSFORM[3].xyz = gun_barrel_pos;
    // We store the target in the VELOCITY or a custom variable 
    // so the 'process' step knows where to go
    VELOCITY = normalize(dir) * speed; // Adjust '5.0' to change travel speed
	
	// 3. ORIENTATION (The "Look At" Logic)
    // We need to align the particle's Forward vector with the direction
    vec3 forward = normalize(dir);
    
    // Pick a temporary 'up' vector (world up)
    vec3 temp_up = vec3(0.0, 1.0, 0.0);
    
    // If the direction is nearly vertical, we need a different temp_up 
    // to avoid a cross-product error (Gimbal lock)
    if (abs(dot(forward, temp_up)) > 0.99) {
        temp_up = vec3(0.0, 0.0, 1.0);
    }
    
    // Calculate Right and Up vectors using Cross Products
    vec3 right = normalize(cross(temp_up, forward));
    vec3 up = cross(forward, right);

    // 4. Apply to TRANSFORM matrix
    // This sets the rotation and scaling (Basis)
    TRANSFORM[0].xyz = right;
    TRANSFORM[1].xyz = forward;
    TRANSFORM[2].xyz = -up;
}