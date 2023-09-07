extends CharacterBody2D

@export var destination = Vector2.ZERO
@export var max_speed = 300
@export var acceleration = 500
var frame = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	frame +=1
	
	if(frame/1 == 1 || $AnimationPlayer.current_animation != 'hit'):
		$AnimationPlayer.play("travel")
	destination = get_global_mouse_position() - global_position
	
	
	if(position.distance_to(destination + global_position) < 5):#Change to check for collision instead, currently just for testing
		$AnimationPlayer.play('hit')
		rotation = 0
	else:
		
		look_at(get_global_mouse_position())
		position = position.move_toward(destination * max_speed, delta * acceleration)
