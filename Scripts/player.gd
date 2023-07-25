extends CharacterBody2D
#Player code
#Has no depencies on parent nodes
#Can move and attack
#8 directional movement
#All directions can be attacked
var input_vector = Vector2.ZERO

const acceleration = 700 #Multiplied by delta
const friction = 250 #Multiplied by delta
const max_speed = 150 # NOT multiplied by delta
const attack_movement = 400 #Multiplied by delta

var max_health = 1000
var current_health = max_health
var pushBackStrength = 0
var frame = 0
var playerSpritePlayer = null
var playerSpriteTree = null
var animationState = null
var attackSpritePlayer = null
var playerPosition = Vector2.ZERO
var frameRecovery = 0
var mouse_coordinates = Vector2.ZERO
var previousBlend = Vector2.ZERO
var knockBackDirection = 1
var assailantPosition = Vector2.ZERO
@onready var healthbar = $healthbar
@onready var shader = self
var listOfSprites = []

var state = MOVE

signal parried

enum {
	MOVE,
	DODGE,
	ATTACK,
	TAKEHIT,
	DEAD,
	PARRY
}

func _ready():#Called when node loads into the scene, children ready functions run first
	
	velocity = Vector2.ZERO
	playerSpritePlayer = $PlayerSpriteAnimPlayer
	playerSpriteTree = $PlayerSpriteAnimTree
	attackSpritePlayer = $attackContainer/AttackSpritePlayer
	post_initialize(playerSpriteTree)
	
	for i in get_children():
		if i is Sprite2D:
			listOfSprites.append(i)
	
	shader = shader.get("material")
	change_sprite("NakedWizard_armed")

func post_initialize(animation_tree):
	animationState = animation_tree.get("parameters/playback")
	

func _physics_process(_delta):#Runs per frame, contains starting player state machine
	
	frame += 1
	match state:
		
		MOVE:
			move_state(_delta)
			
		DODGE:
			pass
			
		ATTACK:
			
			attack_state(_delta)
		TAKEHIT:
			take_hit_state(_delta)
		PARRY:
			parry_state(_delta)
		DEAD:
			dead_state(_delta)
	
			
	
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
		
	elif(velocity != Vector2.ZERO):#Friction
		
		playerSpriteTree.set("parameters/IdleBlend/blend_position", previousBlend)
		animationState.travel("IdleBlend")
		velocity = velocity.move_toward(Vector2.ZERO, friction * _delta)
	
	if (Input.is_action_just_pressed("click")):#Attack state
		state = ATTACK
	else:
		knockBackDirection = 1
	
	if (Input.is_action_just_pressed("parry")):
		state = PARRY
	move_and_slide()


func attack_state(_delta):#State machine for attack combos will go here
	
	mouse_coordinates = get_local_mouse_position()
	mouse_coordinates = mouse_coordinates.normalized()
	
	if(attackSpritePlayer.current_animation_position == 0):
		
		attackSpritePlayer.play("melee_attack")
		change_sprite("NakedWizard_unequipped")
		
	elif(attackSpritePlayer.current_animation_position < attackSpritePlayer.current_animation_length):
		
		velocity = velocity.move_toward(knockBackDirection * mouse_coordinates * attack_movement, attack_movement * _delta)
	
	elif(attackSpritePlayer.current_animation_position == attackSpritePlayer.current_animation_length):
		
		attackSpritePlayer.stop()
		state = MOVE
		change_sprite("NakedWizard_armed")
		#velocity = Vector2.ZERO
	move_and_slide()

func take_hit_state(_delta):

	var pushBackStrength = 150

	var pushBackDirection = position - assailantPosition

	pushBackDirection = pushBackDirection.normalized()

	if(playerSpritePlayer.current_animation_position == 0):

		change_sprite("NakedWizard_hurt_armed")
		playerSpritePlayer.play("take_hit")

	elif(playerSpritePlayer.current_animation_position < playerSpritePlayer.current_animation_length):

		velocity = velocity.move_toward(pushBackDirection * pushBackStrength, pushBackStrength)

	elif(playerSpritePlayer.current_animation_position == playerSpritePlayer.current_animation_length):

		playerSpritePlayer.stop()
		state = MOVE
		change_sprite("NakedWizard_armed")
		
	if(current_health <= 0):
		
		state = DEAD
		
	move_and_slide()

func dead_state(_delta):
	pass

func parry_state(_delta):
	mouse_coordinates = get_local_mouse_position()
	mouse_coordinates = mouse_coordinates.normalized()
	
	if(attackSpritePlayer.current_animation_position == 0):
		
		attackSpritePlayer.play("parry_shield")
		shader.set_shader_parameter("applied", true)
	elif(attackSpritePlayer.current_animation_position == attackSpritePlayer.current_animation_length):
		
		attackSpritePlayer.stop()
		state = MOVE
		velocity = Vector2.ZERO
		shader.set_shader_parameter("applied", false)
	move_and_slide()


func _on_attack_hit_box_area_entered(area):
	if (area.name == "Hurtbox"):
		knockBackDirection = -1
		velocity = Vector2.ZERO

func _on_player_hurtbox_area_entered(area):
	if(area.get_children()[0].disabled == false):
		if(area.name == 'enemy_attack_hitbox' && state != PARRY):
			state = TAKEHIT
			assailantPosition = area.get_parent().get_parent().global_position
			velocity = Vector2.ZERO
			if(attackSpritePlayer.current_animation != ''):
				
				shader.set_shader_parameter("applied", false)
				attackSpritePlayer.get_parent().abort_animation()
			update_healthbar(area.get_parent().get_parent().currentDamage, area.get_parent().get_parent().currentKnockbackStrength)
		elif(state == PARRY):
			parried.emit(state)
			if(attackSpritePlayer.current_animation != ''):
				attackSpritePlayer.stop()
				shader.set_shader_parameter("applied", false)
func update_healthbar(health_change, knock_back_strength):#pass in negative values to increase health
	
	current_health -= health_change
	healthbar.value = (current_health / max_health) * 100
	print("Health bar value is " + str(healthbar.value))
	pushBackStrength = knock_back_strength

func change_sprite(spriteName):
	
	for i in listOfSprites:
		if i.name != spriteName:
			i.hide()
		else:
			i.show()
			

