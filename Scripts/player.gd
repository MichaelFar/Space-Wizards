extends CharacterBody2D


var input_vector = Vector2.ZERO

const acceleration = 700 #Multiplied by delta
const friction = 250 #Multiplied by delta
const max_speed = 150 # NOT multiplied by delta
const attack_movement = 50 #Multiplied by delta


var playerSpritePlayer = null
var playerSpriteTree = null
var animationState = null
var attackSpritePlayer = null
var playerPosition = Vector2.ZERO
var frameRecovery = 0
var mouse_coordinates = Vector2.ZERO
var previousBlend = Vector2.ZERO


var state = MOVE

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

func _physics_process(_delta):#Runs per frame, contains starting player state machine
	
	match state:
		
		MOVE:
			move_state(_delta)
			
		DRIFT:
			pass
			
		ATTACK:
			attack_state(_delta)
		
func move_state(_delta):
	
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input_vector = input_vector.normalized()
	
	playerPosition = self.position
	
	#playerSpriteTree.set("parameters/IdleBlend/blend_position", input_vector)
	#animationState.travel("IdleBlend")
	
	if (Input.is_action_just_pressed("click")):

		state = ATTACK
		mouse_coordinates = get_local_mouse_position()
		velocity = Vector2.ZERO
	if input_vector != Vector2.ZERO:
		
		playerSpriteTree.set("parameters/IdleBlend/blend_position", input_vector)
		playerSpriteTree.set("parameters/MoveBlend/blend_position", input_vector)
		animationState.travel("MoveBlend")
		previousBlend = input_vector
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * _delta)
		
		print("Moving towards " + str(velocity))
	
	elif(velocity != Vector2.ZERO && state != ATTACK):
		
		playerSpriteTree.set("parameters/IdleBlend/blend_position", previousBlend)
		animationState.travel("IdleBlend")
		velocity = velocity.move_toward(Vector2.ZERO, friction * _delta)
	
	print("Mouse coordinates in move state " + str(mouse_coordinates))
	print("Current velocity vector", velocity)	
	#move_and_collide(velocity * _delta)
	move_and_slide()

func attack_state(_delta):#State machine for attack combos will go here
	
	if(attackSpritePlayer.current_animation_position == 0):
		attackSpritePlayer.play("melee_attack")
		
	elif(attackSpritePlayer.current_animation_position < attackSpritePlayer.current_animation_length):
		print("Now applying attack momentum, velocity = " + str(velocity))
		velocity = velocity.move_toward(mouse_coordinates, attack_movement * _delta)
	elif(attackSpritePlayer.current_animation_position == attackSpritePlayer.current_animation_length):
		attackSpritePlayer.stop()
		state = MOVE
		#velocity = Vector2.ZERO
	move_and_slide()
	
	print("Velocity while attacking " + str(velocity))
	print("Mouse position in attack state " + str(mouse_coordinates))	
