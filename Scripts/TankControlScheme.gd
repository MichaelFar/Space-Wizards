extends CharacterBody2D


var input_vector = Vector2.ZERO

const acceleration = 250 #Multiplied by delta
const friction = 250 #Multiplied by delta
const max_speed = 100 # NOT multiplied by delta

var playerSpritePlayer = null
var playerSpriteTree = null
var animationState = null
var attackSpritePlayer = null
var playerPosition = Vector2.ZERO
var frameRecovery = 0
var state = MOVE
var blendCoordinates = Vector2.ZERO
var destinationVector = Vector2.ZERO


var playerAngle = 0
var rotationStrength = 0
var rotationSpeed = 0

enum {
	MOVE,
	DRIFT,
	ATTACK
}


func _ready():#Called when node loads into the scene, children ready functions run first
	
	velocity = Vector2.ZERO
	playerSpritePlayer = $PlayerSpriteAnimPlayer
	playerSpriteTree = $PlayerSpriteAnimTree
	attackSpritePlayer = $AttackSpritePlayer
	post_initialize(playerSpriteTree)

func post_initialize(animation_tree):#Bug in godot where i needed to wrap this in a function to get it to run
	animationState = animation_tree.get("parameters/playback")
	playerPosition = self.position

	destinationVector.x = playerPosition.x 
	destinationVector.y = playerPosition.y 
	playerAngle = playerPosition.angle()

func _physics_process(_delta):#Runs per frame (delta is the difference in time between the current frame and the last frame)
	
	match state:
		
		MOVE:
			move_state(_delta)
			if (Input.is_action_just_pressed("click")):
				state = ATTACK
			
		DRIFT:
			pass
			
		ATTACK:
			attack_state(_delta)
			state = MOVE
				
	

func move_state(_delta):
	
#	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	rotationStrength = Input.get_action_strength("left") - Input.get_action_strength("right")
#	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
#	input_vector = input_vector.normalized()
	print("Rotation strength is " + str(rotationStrength))
	playerPosition = self.position
	#destinationVector = destinationVector.normalized()
	
	
	if(rotationStrength != 0):
		rotationStrength *= 125
		#clamp(rotationStrength,0, 1000)
		playerAngle = playerPosition.angle_to_point(destinationVector) * rotationSpeed
		destinationVector = destinationVector.rotated(playerAngle)
		rotationSpeed = ((rotationStrength * PI/180)) * _delta
	print("Rotation speed is " + str(rotationSpeed))
	
	print("Player angle in degrees is: " + str(playerAngle * (180/PI)))
	
	playerSpriteTree.set("parameters/IdleBlend/blend_position", destinationVector)
	print(playerSpriteTree.get("parameters/IdleBlend/blend_position"))
	animationState.travel("IdleBlend")
	print("Player position is " + str(playerPosition))
	print("Destination position is " + str(destinationVector))
	
	#if (Input.is_action_pressed("up")):
		#destinationVector = destinationVector.normalized()
	playerSpriteTree.set("parameters/IdleBlend/blend_position", destinationVector)
	playerSpriteTree.set("parameters/MoveBlend/blend_position", destinationVector)
	animationState.travel("MoveBlend")
	velocity = velocity.move_toward(destinationVector * max_speed, acceleration * _delta)
#	elif(velocity != Vector2.ZERO):
#
#		animationState.travel("IdleBlend")
#		velocity = velocity.move_toward(Vector2.ZERO, friction * _delta)
#		#destinationVector = playerPosition
#	else:
#
#		animationState.travel("IdleBlend")
	move_and_slide()
	


func attack_state(_delta):
	attackSpritePlayer.play("melee_attack")
	
	
	
