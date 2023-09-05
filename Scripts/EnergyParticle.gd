extends CharacterBody2D

var frame = 0

var supplied_position = Vector2.ZERO
var acceleration = 200
var max_speed = 400
var point = null
var offset_iterator = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	set_supplied_position(point.global_position - global_position)
	
	frame +=1
	
	if frame % 3 == 0:
		rotation += 90
		
	if !(position.distance_to(supplied_position + position) <= 5):
		position = position.move_toward(max_speed * supplied_position, delta * acceleration)
	else:
		rotation = PI * 1.5
		if frame % 3 == 0:
			get_children()[0].offset.x += offset_iterator
			if(abs(get_children()[0].offset.x) > 3):
				offset_iterator = offset_iterator * -1
	move_and_slide()
func set_supplied_position(target_position):
	supplied_position = target_position
