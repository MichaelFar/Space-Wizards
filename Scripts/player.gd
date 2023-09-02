extends CharacterBody2D
#Player code
#Has no depencies on parent nodes
#Can move and attack
#8 directional movement
#All directions can be attacked
var input_vector = Vector2.ZERO
var shouldDie = false
var parry_active = false

var acceleration = 450 #Multiplied by delta
var prevAcceleration = acceleration
var friction = 250 #Multiplied by delta
var max_speed = 150 # NOT multiplied by delta
var attack_movement = 400 #Multiplied by delta

var max_health = 1000
var current_health = max_health
var pushBackStrength = 0
var frame = 0
var attack_points = []

var animationState = null

var playerPosition = Vector2.ZERO
var frameRecovery = 0
var mouse_coordinates = Vector2.ZERO
var previousBlend = Vector2.ZERO
var knockBackDirection = 1
var assailantPosition = Vector2.ZERO
var parry_cool_down_frames = 0
var parry_timer_on = false
var attack_cool_down_frames = 0
var attack_timer_on = false
var hit_enemy = false 
var parried_enemy = false
var successfulHit = false
var dummy_delta = 0

var dodge_frames = 0
var dodge_timer = 0
var dodge_timer_on = false
var parent = null
var enemy_damage = 0
var enemy_knockback = 0
var parry_energy = 0

@export var accelerationCoef = 1.8
@export var knockBackHitStrength = 5 #Determines how strong the knockback is when hitting the enemy


var previous_velocity = Vector2.ZERO

var type = 'player'

@onready var healthbar = $healthbar
@onready var shader = self
@onready var hit_box = $player_hurtbox/CollisionShape2D
@onready var playerSpritePlayer = $PlayerSpriteAnimPlayer
@onready var playerSpriteTree = $PlayerSpriteAnimTree
@onready var attackSpritePlayer = $attackContainer/AttackSpritePlayer
@onready var nakedWizardBase = $NakedWizard_base
@onready var attackContainer = $attackContainer
@onready var EnergyPointContainer = $EnergyPointContainer

var listOfSprites = []
var enemyIDs = []

var state = MOVE

signal s_parried
signal s_attack_points

enum {
	MOVE,
	DODGE,
	ATTACK,
	TAKEHIT,
	DEAD,
	PARRY,
	COOLDOWN
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
	
	
	shader = get("material")
	
	change_sprite("NakedWizard_base")
	populate_stats()
	set_collision_mask_value(2, true)
	playerSpriteTree.set("parameters/IdleBlend/blend_position", input_vector)
	playerSpriteTree.set("parameters/MoveBlend/blend_position", input_vector)
	animationState.travel("IdleBlend")
	#material.set_shader_parameter("texture_size", nakedWizardBase.texture.get_size())
	parent.spawned_enemy.connect(connect_hit_signal)

func post_initialize(animation_tree):
	
	animationState = animation_tree.get("parameters/playback")
	parent = get_parent()
	
func populate_stats():
	
	var stat_sheet = $player_stat_sheet
	max_health = stat_sheet.max_health
	acceleration = stat_sheet.acceleration #Multiplied by delta
	friction = stat_sheet.friction #Multiplied by delta
	max_speed = stat_sheet.max_speed # NOT multiplied by delta
	attack_movement = stat_sheet.attack_movement #Multiplied by delta
	current_health = max_health
	
func connect_hit_signal(enemy_id):
	
	enemy_id.player_hit_me.connect(successful_hit)
func _physics_process(_delta):#Runs per frame, contains starting player state machine
	#successfulHit = false
	#s_attack_points.emit(attack_points)
	dummy_delta = _delta
	frame += 1
	match state:
		
		MOVE:
			move_state(_delta)
		DODGE:
			dodge_state(_delta)
		ATTACK:
			attack_state(_delta)
		TAKEHIT:
			take_hit_state(_delta)
		PARRY:
			parry_state(_delta)
		DEAD:
			dead_state(_delta)
		COOLDOWN:
			cool_down_state(_delta)
	
	if(dodge_timer_on):
		dodge_timer += 1
		if(dodge_timer / 15 == 1):
			dodge_timer_on = false
			dodge_timer = 0
	
	if(parry_timer_on):
		parry_cool_down_frames += 1
		print("Parry cooldown frames is " + str(parry_cool_down_frames))
		if(parry_cool_down_frames / 30 == 1):
			
			parry_cool_down_frames = 0
			parry_timer_on = false
	
func move_state(_delta):
	
	mouse_coordinates = get_local_mouse_position()
	mouse_coordinates = mouse_coordinates.normalized()
	
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	playerPosition = self.position
	
	if (input_vector != Vector2.ZERO):#Movement
		
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
	
	if(!attack_timer_on):
		
		if(InputBuffer.is_action_press_buffered('click') && !Input.is_action_just_released('click')):#Attack state
			#print("Player just attacked")
			state = ATTACK
			if('parry' in attackSpritePlayer.current_animation):
				print("Attack will play after parry")
				attackSpritePlayer.queue("melee_attack")
				attackSpritePlayer.seek(attackSpritePlayer.current_animation_length, true)
			else:
				attackSpritePlayer.play('melee_attack')
			nakedWizardBase.switch_weapon_sprite("")
			attack_timer_on = true
			#acceleration = prevAcceleration * accelerationCoef
			#knockBackDirection = -1 * knockBackHitStrength
		else:
			knockBackDirection = knockBackHitStrength
		
				
	if(!parry_timer_on):
		if (InputBuffer.is_action_press_buffered('parry') && !Input.is_action_just_released('parry')):
			state = PARRY
			#toggle_parry_active(true)
			parry_timer_on = true
			attack_cool_down_frames = 0
			attack_timer_on = false
			attackSpritePlayer.play("parry_whiff")
			acceleration = prevAcceleration * accelerationCoef
			
			
		else:
			parried_enemy = false
	if(!dodge_timer_on):
		
		if(InputBuffer.is_action_press_buffered('ui_select') && !Input.is_action_just_released('ui_select')):
			
			print("Dodge state entered")
			state = DODGE
			previous_velocity = input_vector * max_speed
			attackContainer.abort_animation()
	move_and_slide()

func attack_state(_delta):#State machine for attack combos will go here
	
	mouse_coordinates = get_local_mouse_position()
	mouse_coordinates = mouse_coordinates.normalized()
	
	if('parry' in attackSpritePlayer.current_animation):
		attackSpritePlayer.queue("melee_attack")
		attackSpritePlayer.seek(attackSpritePlayer.current_animation_length, true)
		
	if(attackSpritePlayer.current_animation_position == 0):
		velocity = Vector2.ZERO
		attackSpritePlayer.play("melee_attack")
		#change_sprite("NakedWizard_base")
		nakedWizardBase.switch_weapon_sprite("")
	
	elif(attackSpritePlayer.current_animation_position < attackSpritePlayer.current_animation_length):
		print(str(knockBackDirection))
		velocity = velocity.move_toward(knockBackDirection * mouse_coordinates * attack_movement, abs(knockBackDirection) * attack_movement * _delta)
	
	elif(attackSpritePlayer.current_animation_position == attackSpritePlayer.current_animation_length):
		
		#hit_enemy = !attack_timer_on
		print(" attack timer on is " + str(attack_timer_on))
		print("Hit enemy is " + str(hit_enemy) + " and attack timer is set to " + str(attack_timer_on))
		attackContainer.abort_animation()
		state = COOLDOWN
		change_sprite("NakedWizard_base")
		nakedWizardBase.switch_weapon_sprite("NakedwizardBroom01")
		#velocity = Vector2.ZERO
	move_and_slide()

func take_hit_state(_delta):

	var pushBackStrength = enemy_knockback

	var pushBackDirection = position - assailantPosition

	pushBackDirection = pushBackDirection.normalized()

	if(playerSpritePlayer.current_animation_position == 0):
		attackSpritePlayer.clear_queue()
		change_sprite("NakedWizard_hurt_armed")
		playerSpritePlayer.play("take_hit")
		shader.set_shader_parameter("applied", true)
		set_shader_time()
		
		
	elif(playerSpritePlayer.current_animation_position < playerSpritePlayer.current_animation_length):

		velocity = velocity.move_toward(pushBackDirection * enemy_knockback, enemy_knockback)

	elif(playerSpritePlayer.current_animation_position == playerSpritePlayer.current_animation_length):
		playerSpritePlayer.stop()
		attackContainer.abort_animation()
		state = MOVE
		change_sprite("NakedWizard_base")
		shader.set_shader_parameter("applied", false)
		#Shader unapplies here in animation player
		
		
	move_and_slide()

func dead_state(_delta):
	
	shader.set_shader_parameter("modulate", Vector4(0,0,0,0))
	animationState.stop()
	if(shouldDie):
		playerSpritePlayer.stop()
		
		queue_free()
	
func parry_state(_delta):
	mouse_coordinates = get_local_mouse_position()
	mouse_coordinates = mouse_coordinates.normalized()
	
	
	print("Current animation is " + attackSpritePlayer.current_animation)
	queue_parry_hit()
	if(attackSpritePlayer.current_animation_position == attackSpritePlayer.current_animation_length):
		
		if(!parried_enemy):
			attackSpritePlayer.queue("RESET")
			
		state = MOVE
		
		if(!parried_enemy):	
			velocity = Vector2.ZERO
		
	
	if(attackSpritePlayer.get_queue().size() != 0):
		print("Queued animation for attack player is " + str(attackSpritePlayer.get_queue()))
	move_and_slide()

func _on_attack_hit_box_area_entered(area):
	
	if (area.name == "Hurtbox"):
		
		knockBackDirection = -1 * knockBackHitStrength
		velocity = Vector2.ZERO
		hit_enemy = true
		print("When hit enemy attack timer is " + str(attack_timer_on))
		

func _on_player_hurtbox_area_entered(area):
	if(area.get_children()[0].disabled == false):
		if(area.name == 'enemy_attack_hitbox' && !parry_active && state != DODGE && state != DEAD):
			
			state = TAKEHIT
			assailantPosition = area.get_enemy_id().global_position
			velocity = Vector2.ZERO
			attack_cool_down_frames = 0
			attack_timer_on = false
			
			get_enemy_attack_stats(area.get_enemy_id())
			print("Player will take " + str(enemy_damage) + " damage")
			
			if(attackSpritePlayer.current_animation != ''):
				
				shader.set_shader_parameter("applied", false)
			
			attackContainer.abort_animation()#Hope this fixed the smear bug (later michael edit: likely did fix)
				
			update_healthbar(enemy_damage)
		elif(area.name == 'enemy_attack_hitbox' && parry_active):
			s_parried.emit(area.get_enemy_id())#Signal sent to appropriate enemy that they were parried
			parry_timer_on = false
			parried_enemy = true
			parry_cool_down_frames = 0
			attack_cool_down_frames = 0
			attack_timer_on = false
			print("Position of animation for " + attackSpritePlayer.current_animation + " is " + str(attackSpritePlayer.current_animation_position))
			attackContainer.parryDirection = area.get_enemy_id().global_position
			get_enemy_attack_stats(area.get_enemy_id())
			EnergyPointContainer.gain_energy(parry_energy, area.get_enemy_id().global_position)
			
				
func update_healthbar(health_change):#pass in negative values to increase health
	
	current_health = clamp(current_health - health_change, -1, max_health)
	
	print("Health percentage is " + str((current_health / max_health) * 100.0))
	healthbar.value = (current_health / max_health) * 100.0
	print("Health bar value is " + str(healthbar.value))
	
	if(current_health <= 0):
		state = DEAD
		change_sprite('NakedWizard_base')
		playerSpritePlayer.stop()
		animationState.stop()
		playerSpritePlayer.play('death')
	
func change_sprite(spriteName):
	
	for i in listOfSprites:
		if i.name != spriteName:
			i.hide()
		else:
			i.show()
	
func cool_down_state(_delta):
		
	var cool_down_target = 20
	attack_cool_down_frames += 1
	
	if(hit_enemy):
		cool_down_target = 15
		#acceleration = prevAcceleration * accelerationCoef
		#move_state(_delta)
		
#	if(parry_cool_down_frames == 0):
#
#		if (InputBuffer.is_action_press_buffered('parry')):
#
#			state = PARRY
#			parry_timer_on = true
#			attack_cool_down_frames = 0
#			attack_timer_on = false
#			attackSpritePlayer.play("parry_whiff")
#			acceleration = prevAcceleration * accelerationCoef
	
	velocity = velocity.move_toward(Vector2.ZERO, friction * 1.5 * _delta)
	
	if(attack_cool_down_frames / cool_down_target == 1):
		print("attack cool down is done")
		attack_cool_down_frames = 0
		attack_timer_on = false
		state = MOVE
		hit_enemy = false
		acceleration = prevAcceleration
		
	move_and_slide()

func dodge_state(_delta):#Candidate for player sheet
	
	dodge_frames += 1
	var dodge_max_speed = 800
	var dodge_accel = dodge_max_speed * 2
	attack_cool_down_frames = 0
	attack_timer_on = false
	playerSpriteTree.set("parameters/IdleBlend/blend_position", input_vector)
	playerSpriteTree.set("parameters/MoveBlend/blend_position", input_vector)
	animationState.travel("MoveBlend")
	
	velocity = velocity.move_toward(input_vector * dodge_max_speed, dodge_accel * _delta)
	
	if dodge_frames == 1:
		EnergyPointContainer.lose_energy(1)
		print("1 Energy for dodge used")
	if(dodge_frames / 15 == 1):
		
		dodge_frames = 0
		state = MOVE
		velocity = previous_velocity
		hit_box.disabled = false
		dodge_timer_on = true
		dodge_timer = 0
		
	else:
		
		hit_box.disabled = true
		
	set_collision_mask_value(2, !hit_box.disabled) #Changes the collision mask when dodging to go through enemies
	move_and_slide()

func get_enemy_attack_stats(enemy_id):
	
	var enemy_sheet = enemy_id.stat_sheet
	enemy_damage = enemy_sheet.damage
	enemy_knockback = enemy_sheet.knockback_strength
	parry_energy = enemy_sheet.parry_energy # How much energy is gained from parry

func node_type():
	
	type = 'player'
	
func player_must_die():
	
	shouldDie = true
	
func successful_hit():
	
	attackContainer.play_hit()
	print("play_hit() has run")
	
func play_hit():
	
	if(successfulHit):
		print("Hit the enemy")
		
func toggle_parry_active(active):#Called in animation parry_whiff and parry_hit
	parry_active = active
	
	if(active):
		print("Parry is active " + str(frame))
	else:
		print("Parry is inactive" + str(frame))
	

func queue_parry_hit():#Called in _on_player_hurtbox_area_entered()
	
	if(parried_enemy):
		
		attackSpritePlayer.queue("parry_hit")
		print("Queued animation for attack player is " + str(attackSpritePlayer.get_queue()))
		
		attackSpritePlayer.seek(attackSpritePlayer.current_animation_length)
		state = MOVE
		attack_cool_down_frames = 0
		attack_timer_on = false
		
		

func set_shader_time():
	
	shader.set_shader_parameter("start_time", Time.get_ticks_msec() / 1000.0)#Give time in seconds since engine has started


