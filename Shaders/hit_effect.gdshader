shader_type canvas_item;

uniform float blue = 1.0;
uniform float red = .75;
uniform int amount = 200;
uniform bool applied = false;


void fragment()
{
	vec4 original_color = texture(TEXTURE, UV);
	
	if(!applied)
	{
		COLOR = original_color;
	}
	else
	{
		vec2 grid_uv = round(UV * float(amount)) / float(amount);
	
		vec4 text = texture(TEXTURE, grid_uv);
		
		COLOR = text;
	 	
		COLOR.r = red;
	}
}
