extends Sprite2D


@onready var parent_material = get_parent().get("material")

func _ready():
	parent_material.set_shader_parameter("nb_frames",Vector2(hframes, vframes))


func _process(delta):
	
	parent_material.set_shader_parameter("frame_coords",frame_coords)
	parent_material.set_shader_parameter("velocity",get_parent().velocity)
