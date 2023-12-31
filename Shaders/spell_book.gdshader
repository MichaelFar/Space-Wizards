shader_type canvas_item;

uniform vec2 frame_coord = vec2(0.0);
uniform vec4 color : source_color = vec4(1.0);
uniform float width : hint_range(0, 10) = 1.0;
uniform int pattern : hint_range(0, 2) = 0; // diamond, circle, square
uniform bool inside = false;
uniform bool add_margins = true; // only useful when inside is false
uniform bool enabled = false;

void vertex() {
	if(enabled){
		if (add_margins) {
			VERTEX += (UV * 2.0 - 1.0) * width;
		}
	}
}

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	if(enabled){
		for (float i = -ceil(width); i <= ceil(width); i++) {
			float x = abs(i) > width ? width * sign(i) : i;
			float offset;

			if (pattern == 0) {
				offset = width - abs(x);
			} else if (pattern == 1) {
				offset = floor(sqrt(pow(width + 0.5, 2) - x * x));
			} else if (pattern == 2) {
				offset = width;
			}

			for (float j = -ceil(offset); j <= ceil(offset); j++) {
				float y = abs(j) > offset ? offset * sign(j) : j;
				vec2 xy = uv + texture_pixel_size * vec2(x, y);

				if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a == 0.0) == inside) {
					return true;
				}
			}
		}

	return false;
	}
}

void fragment() {
	vec2 uv = UV;
	if(enabled) {
		if (add_margins) {
			vec2 real_texture_size = 1.0 / TEXTURE_PIXEL_SIZE;

		    // This is texture size when add margin equal to 
		    // width of the outline*2 (left and right / top and down)
		    vec2 added_margin_texture_pixel_size = 1.0 / (real_texture_size + (width*2.0));

		    // width in range (0,1), respected to the new texture size
		    vec2 width_size = added_margin_texture_pixel_size * width;
		    // shift the original uv bottom-right for 'width' unit 
		    // Calculate how much bigger is the new size compared to the old one
		    vec2 shifted_uv = UV - width_size;
		    // Then scale the uv down to that ratio
		    vec2 ratio = TEXTURE_PIXEL_SIZE / added_margin_texture_pixel_size;
		    vec2 scaled_shifted_uv = shifted_uv * ratio;

		    // sample the original texture with new uv to scale it down
		    // to the original size
		    
		    COLOR= texture(TEXTURE, scaled_shifted_uv);
//			vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));
//
//			uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
//
//			if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
//				COLOR.a = 0.0;
//			} else {
//				COLOR = texture(TEXTURE, uv);
//			}
		} else {
			COLOR = texture(TEXTURE, uv);
		}

		if ((COLOR.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
			COLOR.rgb = inside ? mix(COLOR.rgb, color.rgb, color.a) : color.rgb;
			COLOR.a += (1.0 - COLOR.a) * color.a;
		}
	}
}
//shader_type canvas_item;
//
//uniform vec4 line_color : source_color = vec4(1);
//uniform float line_thickness : hint_range(0, 10) = 1.0;
//
//void fragment() {
//	vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
//
//	float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
//	outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
//	outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
//	outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
//	outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
//	outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
//	outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
//	outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
//	outline = min(outline, 1.0);
//
//	vec4 color = texture(TEXTURE, UV);
//	COLOR = mix(color, line_color, outline - color.a);
//}