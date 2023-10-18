extends CharacterBody2D
#Player code
#Has no depencies on parent nodes
#Can move, attack, parry, dodge, and soon cast spells
#8 directional movement
#All directions can be attacked
var input_vector = Vector2.ZERO
var shouldDie = false
var parry_active = false
var dodgeProgress = 0
var acceleration = 450 #Multiplied by delta
var prevAcceleration = acceleration
var friction = 250 #Multiplied by delta
var max_speed = 150 # NOT multiplied by delta
var previous_max_speed = max_speed
var attack_movement = 400 #Multiplied by delta

var progressIterator = 0
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
var halfwayReached = false
var dodge_frames = 0
var dodge_timer = 0
var dodge_timer_on = false
var parent = null
var enemy_damage = 0
var enemy_knockback = 0
var parry_energy = 0
var store_state = 0 #Certain actions have multiple potential final states they can transition to, such as dodging with the book open
@export var accelerationCoef = 1.8
@export var knockBackHitStrength = 5 #Determines how strong the knockback is when hitting the enemy
@export var dodgeFrameTarget = 20
var dodge_particle_linger = false
var dodge_linger_frames = 0
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
@onready var spellContainer = $SpellContainer
@onready var resourcePreloader = $ResourcePreloader
@onready var stat_sheet = $player_stat_sheet
@onready var dodge_particle = $DodgeParticle

var PlayerCam = null
var listOfSprites = []
var enemyIDs = []

var state = MOVE

signal s_parried
signal s_attack_points

var originalShader = material

enum {
	MOVE,
	DODGE,
	ATTACK,
	TAKEHIT,
	DEAD,
	PARRY,
	COOLDOWN,
	BOOKOPEN
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
	dodge_particle.emitting = false
	shader = get("material")
	originalShader = shader
	change_sprite("NakedWizard_base")
	populate_stats()
	set_collision_mask_value(2, true)
	playerSpriteTree.set("parameters/IdleBlend/blend_position", input_vector)
	playerSpriteTree.set("parameters/MoveBlend/blend_position", input_vector)
	animationState.travel("IdleBlend")
	#material.set_shader_parameter("texture_size", nakedWizardBase.texture.get_size())
	parent.spawned_enemy.connect(connect_hit_signal)
	globals.playerHealthBar = healthbar

func post_initialize(animation_tree):
	
	animationState = animation_tree.get("parameters/playback")
	parent = get_parent()
	#EnergyPointContainer = $EnergyPointContainer
	PlayerCam = $PlayerCam


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
	var frameRate = 1/_delta
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
		BOOKOPEN:
			RAM_state(_delta)
	
	if(dodge_timer_on):
		dodge_timer += 1
		if(dodge_timer / dodgeFrameTarget == 1):
			dodge_timer_on = false
			dodge_timer = 0
	
	if(parry_timer_on):
		parry_cool_down_frames += 1
		print("Parry cooldown frames is " + str(parry_cool_down_frames))
		if(parry_cool_down_frames / 30 == 1):
			
			parry_cool_down_frames = 0
			parry_timer_on = false
	
	if(dodge_particle_linger):
		var dodge_linger_time = frame - dodge_linger_frames
		
		if(dodge_linger_time / int(frameRate) == 1):
			dodge_particle.emitting = false
			dodge_linger_frames = 0
func move_state(_delta):
	store_state = MOVE
	var camera = GlobalCameraValues.cameraNode
	mouse_coordinates = get_local_mouse_position()
	mouse_coordinates = mouse_coordinates.normalized()
	
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	dodge_particle.scale.x = -1 * input_vector.x
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	playerPosition = position
	
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
	
	if(state != BOOKOPEN):#When in the BOOKOPEN state, certain actions are forbidden
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
				
			else:
				knockBackDirection = knockBackHitStrength
			
		if(!parry_timer_on):
			if (InputBuffer.is_action_press_buffered('parry') 
			&& !Input.is_action_just_released('parry')):
				state = PARRY
				#toggle_parry_active(true)
				parry_timer_on = true
				attack_cool_down_frames = 0
				attack_timer_on = false
				attackSpritePlayer.play("parry_whiff")
				acceleration = prevAcceleration * accelerationCoef
				
			else:
				parried_enemy = false
		
		if(InputBuffer.is_action_press_buffered('cast_spell')):
			if(!spellContainer.spell_cooldown_target):
				spellContainer.shouldCast = true
			
	if(InputBuffer.is_action_press_buffered("RAM")):
		
		if(spellContainer.toggle_book_open()):
			state = BOOKOPEN
			store_state = BOOKOPEN
		else:
			state = MOVE
			#max_speed = previous_max_speed
	if(!dodge_timer_on):
			
			if(InputBuffer.is_action_press_buffered('dodge') && !Input.is_action_just_released('dodge')):
						
				if(state == BOOKOPEN):
					if(spellContainer.is_open):
						spellContainer.toggle_book_open()
					spellContainer.randomize_list()
					store_state = MOVE
				print("Dodge state entered")
				state = DODGE
				previous_velocity = input_vector * max_speed
				attackContainer.abort_animation()
				
	max_speed = previous_max_speed
	
	move_and_slide()

func attack_state(_delta):#State machine for attack combos will go here
	
	mouse_coordinates = PlayerCam.MouseCursor.position
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
		material = resourcePreloader.get_resource("player")
		material.set_shader_parameter("applied", true)
		set_shader_time()
		if(spellContainer.is_open):
			spellContainer.toggle_book_open()
			spellContainer.randomize_list()
		
	elif(playerSpritePlayer.current_animation_position < playerSpritePlayer.current_animation_length):

		velocity = velocity.move_toward(pushBackDirection * enemy_knockback, enemy_knockback)

	elif(playerSpritePlayer.current_animation_position == playerSpritePlayer.current_animation_length):
		playerSpritePlayer.stop()
		attackContainer.abort_animation()
		state = MOVE
		
		change_sprite("NakedWizard_base")
		material.set_shader_parameter("applied", false)
		#Shader unapplies here in animation player
		
	move_and_slide()

func dead_state(_delta):
	
	material.set_shader_parameter("modulate", Vector4(0,0,0,0))
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

func cool_down_state(_delta):
		
	var cool_down_target = 25
	attack_cool_down_frames += 1
	
	if(hit_enemy):
		cool_down_target = 20
		
	velocity = velocity.move_toward(Vector2.ZERO, friction * 1.5 * _delta)
	
	if(attack_cool_down_frames / cool_down_target == 1):
		
		attack_cool_down_frames = 0
		attack_timer_on = false
		state = MOVE
		hit_enemy = false
		acceleration = prevAcceleration
		
	move_and_slide()

func dodge_state(_delta):#Candidate for player sheet
	
	
	progressIterator += 1
	if(progressIterator > dodgeFrameTarget / 2):
		halfwayReached = true
	
	if(halfwayReached):
		dodgeProgress -= 0.04
	else:
		dodgeProgress += 0.04
	dodge_frames += 1
	var progressRatio = dodgeProgress
	var dodge_max_speed = 800
	var dodge_accel = dodge_max_speed * 2
	attack_cool_down_frames = 0
	attack_timer_on = false
	playerSpriteTree.set("parameters/IdleBlend/blend_position", input_vector)
	playerSpriteTree.set("parameters/MoveBlend/blend_position", input_vector)
	animationState.travel("MoveBlend")
	
	velocity = velocity.move_toward(input_vector * dodge_max_speed, dodge_accel * _delta)
	
	if(dodge_frames == 1):
		dodge_particle.emitting = true
		#material = resourcePreloader.get_resource("dodge_material")
		#material.set_shader_parameter("progress", progressRatio)
	if(dodge_frames / dodgeFrameTarget == 1):
		
		dodge_frames = 0
		state = store_state
		store_state = MOVE
		velocity = previous_velocity
		hit_box.disabled = false
		dodge_timer_on = true
		dodge_timer = 0
		material = resourcePreloader.get_resource("player")
		halfwayReached = false
		dodgeProgress = 0.0
		progressIterator = 0
		dodge_particle.emitting = false
		dodge_particle_linger = true
		dodge_linger_frames = frame
	else:
		#material.set_shader_parameter("progress", progressRatio)
		
		hit_box.disabled = true
		
	set_collision_mask_value(2, !hit_box.disabled) #Changes the collision mask when dodging to go through enemies
	move_and_slide()
	

func RAM_state(_delta):
	
	max_speed = previous_max_speed / 2
	
	if(PlayerCam.SpellBook.animationPlayer.current_animation_position == PlayerCam.SpellBook.animationPlayer.current_animation_length):
		if(InputBuffer.is_action_press_buffered("page_left")):
			spellContainer.cycle_spells(-1)
		elif(InputBuffer.is_action_press_buffered("page_right")):
			spellContainer.cycle_spells(1)
	
	move_state(_delta)

func _on_attack_hit_box_area_entered(area):
	
	if (area.name == "Hurtbox"):
		
		knockBackDirection = -1 * knockBackHitStrength
		velocity = Vector2.ZERO
		hit_enemy = true
		print("When hit enemy attack timer is " + str(attack_timer_on))
		attackContainer.play_hit()
		
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
				
				material.set_shader_parameter("applied", false)
			
			attackContainer.abort_animation()#Hope this fixed the smear bug (later michael edit: likely did fix)
				
			update_healthbar(enemy_damage)
		elif(area.name == 'enemy_attack_hitbox' && parry_active):
			s_parried.emit(area.get_enemy_id())#Signal sent to appropriate enemy that they were parried
			parry_timer_on = false
			parried_enemy = true
			parry_cool_down_frames = 0
			attack_cool_down_frames = 0
			attack_timer_on = false
			
			attackContainer.parryDirection = area.get_enemy_id().global_position
			get_enemy_attack_stats(area.get_enemy_id())
			
			EnergyPointContainer.gain_energy(parry_energy, area.get_enemy_id().global_position)
		
				
func update_healthbar(health_change):#pass in negative values to increase health
	
	current_health = clamp(current_health - health_change, -1, max_health)
	
	healthbar.value = (current_health / max_health) * 100.0
	
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
	

func get_enemy_attack_stats(enemy_id):
	
	var enemy_sheet = enemy_id.stat_sheet
	enemy_damage = enemy_sheet.damage
	enemy_knockback = enemy_sheet.knockback_strength
	parry_energy = enemy_sheet.parry_energy # How much energy is gained from parry

func node_type():
	return 'player'
	
	
func player_must_die():
	
	shouldDie = true
	
func successful_hit():
	attackContainer.play_hit()
	#successfulHit = true
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
	
	material.set_shader_parameter("start_time", Time.get_ticks_msec() / 1000.0)#Give time in seconds since engine has started

func reset_knockback_direction():#Called in attack animations
	knockBackDirection = 1
