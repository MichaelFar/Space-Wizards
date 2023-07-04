extends CharacterBody2D


var input_vector = Vector2.ZERO

const acceleration = 700 #Multiplied by delta
const friction = 250 #Multiplied by delta
const max_speed = 150 # NOT multiplied by delta

var animationPlayer = null
var animationTree = null
var animationState = null

func _ready():#Called when node loads into the scene, children ready functions run first
	velocity = Vector2.ZERO
	animationPlayer = $PlayerAnimations
	animationTree = $AnimationTree
	post_initialize(animationTree)

func post_initialize(animation_tree):#Bug in godot where i needed to wrap this in a function to get it to run
	animationState = animation_tree.get("parameters/playback")

func _physics_process(_delta):#Runs per frame (delta is the difference in time between the current frame and the last frame)
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	#input_vector.x = Input.get_axis("ui_left" , "ui_right")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	
	if input_vector != Vector2.ZERO:
		
		animationTree.set("parameters/IdleBlend/blend_position", input_vector)
		animationTree.set("parameters/MoveBlend/blend_position", input_vector)
		animationState.travel("MoveBlend")
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * _delta)
		
		print("Moving towards " + " " + str(velocity))
	elif(velocity != Vector2.ZERO):
	
		animationState.travel("IdleBlend")
		velocity = velocity.move_toward(Vector2.ZERO, friction * _delta)
	else:
		animationState.travel("IdleBlend")
			
	print("Current velocity vector", velocity)	
	#move_and_collide(velocity * _delta)
	move_and_slide()
