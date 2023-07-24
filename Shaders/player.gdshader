shader_type canvas_item;
uniform float blue = 1.0;
uniform float red = 1.0;

uniform bool applied = false;
void fragment()
{
	vec4 original_color = texture(TEXTURE, UV);
 	COLOR = texture(TEXTURE, UV); //read from texture
 	COLOR.b = blue; //set blue channel to 1.0
	COLOR.r = red;
	
	if(!applied)
	{
		COLOR = original_color;
	}
	
}
