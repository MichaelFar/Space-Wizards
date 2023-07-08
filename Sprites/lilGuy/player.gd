extends CharacterBody2D


var input_vector = Vector2.ZERO

const acceleration = 700 #Multiplied by delta
const friction = 250 #Multiplied by delta
const max_speed = 150 # NOT multiplied by delta

var playerSpritePlayer = null
var playerSpriteTree = null
var animationState = null
var attackSpritePlayer = null
var playerPosition = Vector2.ZERO

func _ready():#Called when node loads into the scene, children ready functions run first
	
	velocity = Vector2.ZERO
	playerSpritePlayer = $PlayerSpriteAnimPlayer
	playerSpriteTree = $PlayerSpriteAnimTree
	attackSpritePlayer = $AttackSpritePlayer
	post_initialize(playerSpriteTree)

func post_initialize(animation_tree):#Bug in godot where i needed to wrap this in a function to get it to run
	animationState = animation_tree.get("parameters/playback")

func _physics_process(_delta):#Runs per frame (delta is the difference in time between the current frame and the last frame)
	
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input_vector = input_vector.normalized()
	
	playerPosition = self.position
	print('Player is located at ' + str(playerPosition))
	playerSpriteTree.set("parameters/IdleBlend/blend_position", get_local_mouse_position())
	animationState.travel("IdleBlend")
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	
	if (Input.is_action_just_pressed("click")):
		
		attackSpritePlayer.play("melee_attack")
	
	if input_vector != Vector2.ZERO:
		
		playerSpriteTree.set("parameters/IdleBlend/blend_position", input_vector)
		playerSpriteTree.set("parameters/MoveBlend/blend_position", get_local_mouse_position())
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
