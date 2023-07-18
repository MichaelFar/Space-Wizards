extends CharacterBody2D


var input_vector = Vector2.ZERO

const acceleration = 700 #Multiplied by delta
const friction = 250 #Multiplied by delta
const max_speed = 150 # NOT multiplied by delta
const attack_movement = 400 #Multiplied by delta
#WHILE ATTACK FRICTION GO DOWN (needs implement)
#
var playerSpritePlayer = null
var playerSpriteTree = null
var animationState = null
var attackSpritePlayer = null
var playerPosition = Vector2.ZERO
var frameRecovery = 0
var mouse_coordinates = Vector2.ZERO
var previousBlend = Vector2.ZERO
var knockBackDirection = 1

var state = MOVE

enum {
	MOVE,
	DODGE,
	ATTACK
}

func _ready():#Called when node loads into the scene, children ready functions run first
	
	velocity = Vector2.ZERO
	playerSpritePlayer = $PlayerSpriteAnimPlayer
	playerSpriteTree = $PlayerSpriteAnimTree
	attackSpritePlayer = $AttackSpritePlayer
	post_initialize(playerSpriteTree)

func post_initialize(animation_tree):
	animationState = animation_tree.get("parameters/playback")

func _physics_process(_delta):#Runs per frame, contains starting player state machine
	
	match state:
		
		MOVE:
			move_state(_delta)
			
		DODGE:
			pass
			
		ATTACK:
			
			attack_state(_delta)
		
func move_state(_delta):
	
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	playerPosition = self.position
	
	if input_vector != Vector2.ZERO:#Movement
		
		if(input_vector.x != 0 && input_vector.y != 0):
			if(input_vector.y > 0):
				input_vector.y -= .40
			else:
				input_vector.y += .40
				
		input_vector = input_vector.normalized()
		playerSpriteTree.set("parameters/IdleBlend/blend_position", input_vector)
		playerSpriteTree.set("parameters/MoveBlend/blend_position", input_vector)
		animationState.travel("MoveBlend")
		previousBlend = input_vector
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * _delta)
		
		print("Moving towards " + str(velocity))
	
	elif(velocity != Vector2.ZERO):#Friction
		
		playerSpriteTree.set("parameters/IdleBlend/blend_position", previousBlend)
		animationState.travel("IdleBlend")
		velocity = velocity.move_toward(Vector2.ZERO, friction * _delta)
	
	if (Input.is_action_just_pressed("click")):#Attack state
		state = ATTACK
	else:
		knockBackDirection = 1
	
	move_and_slide()

func _on_hurtbox_area_entered(area):
	print("Player attacked enemy")

func attack_state(_delta):#State machine for attack combos will go here
	
	mouse_coordinates = get_local_mouse_position()
	mouse_coordinates = mouse_coordinates.normalized()
	
	if(attackSpritePlayer.current_animation_position == 0):
		
		attackSpritePlayer.play("melee_attack")
		
	elif(attackSpritePlayer.current_animation_position < attackSpritePlayer.current_animation_length):
		
		velocity = velocity.move_toward(knockBackDirection * mouse_coordinates * attack_movement, attack_movement * _delta)
	
	elif(attackSpritePlayer.current_animation_position == attackSpritePlayer.current_animation_length):
		
		attackSpritePlayer.stop()
		state = MOVE
		#velocity = Vector2.ZERO
	move_and_slide()
	
func _on_attack_hit_box_area_entered(area):
	if (area.name == "Hurtbox"):
		knockBackDirection = -1
		velocity = Vector2.ZERO
	
