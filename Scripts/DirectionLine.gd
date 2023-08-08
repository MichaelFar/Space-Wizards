extends Line2D


# Called when the node enters the scene tree for the first time.
func _ready():
	points[0] = get_parent().global_position - position
	add_point(Vector2.ZERO)
	width = 1.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	points[1] = get_parent().direction + get_parent().global_position
