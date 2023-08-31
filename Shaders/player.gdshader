shader_type canvas_item;

uniform float speed = 3.;

uniform vec4 tint : source_color = vec4(1., 1., 0., 1.);

uniform float span : hint_range(0.1, 1.) = .3;

uniform float start_time = 0.0;
//const float start_time = TIME;
uniform bool applied = false;
float luminance(vec4 colour) {
	return 1.0 - sqrt(0.299*colour.r*colour.r + 0.587*colour.g*colour.g + 0.114*colour.b*colour.b);
}

void fragment() {
	vec4 colour = texture(TEXTURE, UV);
		if(applied)
		{
			float actual_time = start_time - TIME;
			float target = abs(sin(actual_time * PI * speed) * (1. + span));
			if(colour.a > 0.) 
			{
				float lum = luminance(colour);
				float diff = abs(lum - target);
				float mx = clamp(1. - diff / span, 0., 1.);
				colour = mix(colour, tint, mx);
			}
		}
	COLOR = colour;
}