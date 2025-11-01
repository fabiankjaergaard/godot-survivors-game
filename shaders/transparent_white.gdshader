shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	// Make white pixels transparent
	// If the pixel is very close to white (RGB all > 0.9), make it transparent
	if (color.r > 0.9 && color.g > 0.9 && color.b > 0.9) {
		color.a = 0.0;
	}

	COLOR = color;
}
