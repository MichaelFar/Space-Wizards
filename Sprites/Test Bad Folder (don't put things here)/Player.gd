extends CharacterBody2D


func _ready():#Called when node loads into the scene, children ready functions run first
	velocity = Vector2.ZERO
	

var input_vector = Vector2.ZERO

const acceleration = 700 #Multiplied by delta
const friction = 250 #Multiplied by delta
const max_speed = 150 # NOT multiplied by delta

func _physics_process(_delta):#Runs per frame (delta is the difference in time between the current frame and the last frame)
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	#input_vector.x = Input.get_axis("ui_left" , "ui_right")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * _delta)
		print(velocity)
		
	elif(velocity != Vector2.ZERO):
		
		velocity = velocity.move_toward(Vector2.ZERO, friction * _delta)
		
	print("Current velocity vector", velocity)	
	#move_and_collide(velocity * _delta)
	move_and_slide()
