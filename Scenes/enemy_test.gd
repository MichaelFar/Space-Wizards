extends CharacterBody2D

#Generic enemy ai, randomly wanders within a navigation area minus the 'Exclusion Zone'
#This node will crash if there is no player, navigation area, parent with world.gd script, or exclusion zone
#Provides a good basis for ai going forward
#Uses multiple sprite nodes with the same sheet
@export var acceleration = 200
@export var max_speed = 200
var speed = 150
var max_health = 1000.0
var current_health = max_health
var damage_taken = 0.0
var pushBackStrength = 250
var pushBackAcceleration = 0
var poise = 100.0
var max_poise = 0.0
var poise_recovery = 3
var player_poise_damage = 0
var parry_poise_damage = 0
var knockback_resistance = 0
var knockback_modifier = 0 # Poise overkill results in longer knockback
var stun_modifier = 0.0
var velocityClone = Vector2.ZERO
var playerAttackPoints = []
var reserved_point = Vector2.ZERO
var reserved_index = 0

var frame = 0
var state = CHOOSEPOINT
var inclusion_area = Vector2.ZERO
var idle_frames = 0
var chosenPoint = Vector2.ZERO
var children = []
var playerPreviousPosition = Vector2.ZERO
var all_other_reserved_indexes = []


@export var noticeDist = 200
@export var pursueDist = 130
@export var attackDist = 40
@export var path_desired_distance = 50
@export var target_distance = 20

@export var shouldDie = false#Do not change this in the inspector
var attackPosition = Vector2.ZERO
var deadframes = 0
var previousPosition = Vector2.ZERO
var direction = Vector2.ZERO
var stuckFrames = 0
var coolDownFrames = 0
var coolDownTimerOn = false
var validPoints = []
var travelPoints = []
var faceRight = true

var animationPlayer = null



@onready var playerNode = get_node("../Player")
@onready var emoteContainer = $EmoteContainer
@onready var smearContainer = $enemy_attack_container
@onready var healthbar = $Healthbar
@onready var poisebar = $poisebar
@onready var navAgent = $NavigationAgent2D
@onready var rayCastContainer = $RayCastContainer
@onready var parent = get_parent()

@onready var stat_sheet = $pirate_grunt_stat_sheet
@onready var shader = self

var frameRate = 0

var attacks_dict = {}

var player_state = null
var player_damage = 0

signal enemy_attack_stats
signal index_reserved

enum {
	WANDER,
	ATTACK,
	PURSUE,
	IDLE,
	CHOOSEPOINT,
	TAKEHIT,
	NOTICEPLAYER,
	DEAD,
	STAGGERED
}

func _ready():
	#await playerNode.get_node("player_stat_sheet").player_stats
	animationPlayer = $AnimationPlayer
	
	for i in self.get_children():
		
		if i is Sprite2D:
			
			children.append(i)
			
	healthbar.value = 100
	emoteContainer.play_emote('')
	
	if(playerNode != null):
		
		playerNode.s_parried.connect(get_parried)
		playerNode.get_node("player_stat_sheet").player_stats.connect(get_player_stats)
		
	populate_stats()
	shader = shader.get("material")
	playerPreviousPosition = playerNode.position
	for i in parent.enemyChildren:
		if i != self:
			i.index_reserved.connect(get_other_reserved_indexes)
	travelPoints = get_travel_points()
	
func post_initialize():
	playerNode.get_node("player_stat_sheet").player_stats.connect(get_player_stats)	
	
func _physics_process(_delta):#State machine runs per frame
	if(playerNode != null):
		attackPosition = playerNode.position
	frameRate = (1/_delta)
	
	if(int(frame) % (int(frameRate) / 2) == 0 && !(poise <= 0.0)):
		update_poise_bar(poise_recovery)
	
	if(parent.noReservedPoints):
		all_other_reserved_indexes = []
	
	playerAttackPoints = playerNode.attack_points
	
	match state:
		
		CHOOSEPOINT:#CHOOSEPOINT is used to get a valid point to travel to, then state transitions to WANDER
			if(frame > 2):#Give nav time to update
				state = WANDER
			chosenPoint = choose_point(travelPoints)
			animationPlayer.stop()
			animationPlayer.play('enemy_walk')
		WANDER:#Uses A* to navigate to a point, wander_state() is also used for pursuing the player (player position is supplied as an argument)
			wander_state(chosenPoint, _delta)
		ATTACK:
			attack_state(_delta)
		PURSUE:#Supplies a dynamic point (last seen(distance based) player position) to wander_state() function
			pursue_state(_delta)
		NOTICEPLAYER:#Checks how long the player is within noticing distance and determines state change based on this
			notice_player_state(_delta)
		IDLE:#The AI will spend some time in this state if it has not noticed the player and has arrived at its destination
			idle_state(_delta)
		TAKEHIT:#Determines what happens when hit
			take_hit_state(_delta)
		DEAD:
			dead_state(_delta)
		STAGGERED:
			take_hit_state(_delta)
	
	if(parent.playerPosition.distance_to(position) <= noticeDist 
	&& state != NOTICEPLAYER 
	&& state != PURSUE 
	&& state != TAKEHIT
	&& state != ATTACK
	&& state != DEAD
	&& state != STAGGERED):
	#Other states must be interrupted so that the player may be noticed
	#However certain states should not be interrupted, hence the state exclusion in the condition
	#Creates a '?' above the head of an enemy that noticed the player
		change_sprite(get_node('pirate_grunt_1'), chosenPoint)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
		idle_frames = 0
		state = NOTICEPLAYER
		velocity = Vector2.ZERO
		emoteContainer.play_emote('question')
		
	if(coolDownFrames / frameRate >= 1):
		
		coolDownTimerOn = false
		coolDownFrames = 0
		#print("Cooldown timer is now " + str(coolDownTimerOn))
	
	if(coolDownTimerOn):
		
		coolDownFrames += 1	
		#print("Cooldown attack frames for enemy are " + str(coolDownFrames))
	
	else:
		
		smearContainer.supplied_player_position = parent.playerPosition
	
	frame += 1 #Frame tracking for various function
	#print("State is " + str(state))
	
func wander_state(target_point, _delta):
	
	#nav.target_position = target_point
	if(rayCastContainer.debug):
		print("target_point is " + str(target_point) + " and player position is " + str(playerNode.position))
	
	direction = target_point - global_position#nav.get_next_path_position() - global_position
	
	rayCastContainer.supplied_direction = direction.normalized()
	if(parent.compare_float_vectors((direction + global_position), target_point)):
		change_sprite(get_node('pirate_grunt_1'), target_point)
	else:
		change_sprite(get_node('pirate_grunt_1'), direction + global_position)
	
	if(frame % 20 == 0):
		previousPosition = position
	
	if (previousPosition.distance_to(position) < 30):
		stuckFrames += 1
	else:
		stuckFrames = 0
	
	
	
	
	velocity = velocity.lerp(rayCastContainer.suggestedVector * max_speed, acceleration * _delta)
	#print(name + " velocity while in wander_state() is " + str(velocity))
	
	if(self.position.distance_to(target_point) <= target_distance || stuckFrames > 300):
		
		state = IDLE
		idle_frames = 0
		change_sprite(get_node('pirate_grunt_1'), target_point)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
		stuckFrames = 0
		emoteContainer.play_emote('')
	
	if(self.position.distance_to(attackPosition) <= attackDist
	&& state == PURSUE):
		
		state = ATTACK
		print("Self position is " + str(position) + " and target point is " + str(target_point))
		idle_frames = 0
		stuckFrames = 0
		coolDownFrames = 0
		emoteContainer.play_emote('')
		velocity = Vector2.ZERO
		attackPosition = target_point
		animationPlayer.stop()
		change_sprite(get_node('pirate_grunt_1'), parent.playerPosition)
		animationPlayer.play('enemy_attack')
		coolDownTimerOn = true
		smearContainer.supplied_player_position = parent.playerPosition
	
	move_and_slide()

func attack_state(_delta):
	
	if(self.position.distance_to(attackPosition) > attackDist):
		if(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
			print("Player out of range, pursuing")
			playerPreviousPosition = parent.playerPosition
			
			change_sprite(get_node('pirate_grunt_1'), playerPreviousPosition)
			animationPlayer.stop()
			animationPlayer.play('enemy_walk')
			state = PURSUE
			idle_frames = 0
			
			emoteContainer.play_emote('startled')
			animationPlayer.set("speed_scale", 1.0)
	elif(!coolDownTimerOn):
		
		animationPlayer.stop()
		change_sprite(get_node('pirate_grunt_1'),parent.playerPosition)
		animationPlayer.play('enemy_attack')
		animationPlayer.set("speed_scale", 1.0)
		coolDownTimerOn = true

func idle_state(_delta):

	reserved_point = Vector2.ZERO
	velocity = Vector2.ZERO
	idle_frames += 1
	var seconds = 60
	@warning_ignore("integer_division")
	if (idle_frames / seconds == 3):
		state = CHOOSEPOINT
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
	
func choose_point(travelPoints):
	
	var randomPoint = RandomNumberGenerator.new()
	var chosen_point = Vector2.ZERO
	
	chosen_point = travelPoints[randomPoint.randi_range(0, travelPoints.size() - 1)]
	
	return chosen_point

func get_travel_points():
	var travelPoints = []
	
	var choice_radius = 150
	validPoints = parent.validpoints
	
	for i in validPoints:
		if i.distance_to(position) <= choice_radius:
			travelPoints.append(i)

func change_sprite(spriteName, chosen_point):
	
	if(position.x < chosen_point.x):
		faceRight = true
	
	elif(faceRight && position.x > chosen_point.x):
		faceRight = false
	
	for i in children:
		i.flip_h = !faceRight
		if(i.name != spriteName.name):
			i.hide()
		else:
			i.show()

func _on_hurtbox_area_entered(area):
	#Sets the appropriate values and sets the state to TAKEHIT
	#Enemies can be hit during any state
	if(area.get_children()[0].disabled == false):
		if(area.name == 'AttackHitBox' && state != TAKEHIT && state != ATTACK):
			
			velocity = Vector2.ZERO
			animationPlayer.stop()
			playerPreviousPosition = parent.playerNode.position
			change_sprite(get_node("pirate_grunt_1"), playerPreviousPosition)
			animationPlayer.play("take_hit")
			update_healthbar(player_damage)
			update_poise_bar(player_poise_damage)
			
		elif(area.name == 'AttackHitBox' && state == ATTACK):
			
			update_healthbar(player_damage)	
			update_poise_bar(player_poise_damage)
			
			if(state != STAGGERED):
				animationPlayer.set("speed_scale", 0.5)
			else:
				animationPlayer.stop()

func take_hit_state(_delta):
	var pushBackDirection = position - playerPreviousPosition
	
	pushBackDirection = pushBackDirection.normalized()
	
	animationPlayer.set("speed_scale", 1.0 + stun_modifier)
	
	if(animationPlayer.current_animation_position == 0):
		
		if(state == TAKEHIT):
			animationPlayer.play('take_hit')
		elif(state == STAGGERED):
			animationPlayer.play('parried')
	
	elif(animationPlayer.current_animation_position < animationPlayer.current_animation_length):
		
		#print("Pushback acceleration is " + str(pushBackAcceleration))
		velocity = velocity.move_toward(pushBackDirection * pushBackStrength, pushBackAcceleration)# + knockback_modifier), pushBackAcceleration)
		
	elif(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
		
		change_sprite(get_node('pirate_grunt_1'), parent.playerPosition)
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
		state = PURSUE
		idle_frames = 0
		playerPreviousPosition = parent.playerPosition
		emoteContainer.play_emote('exclaim')
		velocity = Vector2.ZERO
		animationPlayer.set("speed_scale", 1.0)
		if(poise <= 0.0):
			update_poise_bar(max_poise)
	
	if(current_health <= 0):
		state = DEAD
	move_and_slide()
	
func notice_player_state(_delta):
	
	change_sprite(get_node("pirate_grunt_1"), playerNode.position)
	idle_frames += 1
	
	if(idle_frames / frameRate == 2 
	&& position.distance_to(parent.playerPosition) <= noticeDist 
	|| position.distance_to(parent.playerPosition) < pursueDist):
		
		playerPreviousPosition = parent.playerPosition
		change_sprite(get_node('pirate_grunt_1'), parent.playerPosition)
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
		state = PURSUE
		idle_frames = 0
		#print("Player position before reserving new attack position is " + str(playerPreviousPosition))
		
		#print("Player position after reserving new attack position is " + str(playerPreviousPosition))
		emoteContainer.play_emote('exclaim')
		
	elif(position.distance_to(parent.playerPosition) > noticeDist):
		
		
		idle_frames = 0
		state = CHOOSEPOINT
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
		emoteContainer.play_emote('')
		
func pursue_state(_delta):
	
	var rand_obj = RandomNumberGenerator
	if(position.distance_to(playerNode.position) <= noticeDist):
		playerPreviousPosition = playerNode.position
#	
#	if(position.distance_to(playerNode.position) <= noticeDist
#	&& !parent.compare_float_vectors(playerPreviousPosition, reserved_point)):
#
#		reserve_attack_position()
#	else:
#		free_attack_position()
	wander_state(playerPreviousPosition, _delta)

func update_healthbar(health_change):#pass in negative values to increase health
	
	if(healthbar != null):
		
		current_health -= health_change
		healthbar.value = (current_health / max_health) * 100
		print("Health bar value is " + str(healthbar.value))
		
		if(current_health <= 0):
			state = DEAD

func dead_state(_delta):
	
	deadframes += 1
	var framerate = 1/_delta
	emoteContainer.play_emote("")
	animationPlayer.set("speed_scale", 1.0)
	
	if(healthbar != null):
		healthbar.queue_free()
		animationPlayer.stop()
		animationPlayer.play('parried')
		poisebar.queue_free()
		
	$CollisionShape2D.disabled = true
	
	if(deadframes / framerate >= 2):
		shader.set_shader_parameter("dissolve_value", clamp(shader.get_shader_parameter("dissolve_value") - 0.015, 0.0, 1.0))
		
		$"DeathEffect-sheet".show()
		animationPlayer.play("death")
			
		if(shouldDie):
			
			animationPlayer.stop()
			queue_free()
			
func flip_h_in_animation():
	
	get_node("pirate_grunt_1").flip_h = !get_node("pirate_grunt_1").flip_h

func get_parried(enemy_id):
	
	print("Self is " + str(self) + " and enemy_id is " + str(enemy_id))
	
	if(enemy_id == self):
		
		update_poise_bar(parry_poise_damage)
		
		velocity = Vector2.ZERO
		animationPlayer.stop()
		playerPreviousPosition = parent.playerNode.position
		change_sprite(get_node("pirate_grunt_1"), playerPreviousPosition)
		animationPlayer.play("parried")
		smearContainer.abort_animation()
		
func get_player_stats(knock_back_strength, damage, poise_damage, parryPoiseDamage):
	
	pushBackStrength = knock_back_strength / 2
	pushBackAcceleration = pushBackStrength + knockback_modifier - knockback_resistance
	player_damage = damage
	player_poise_damage = poise_damage
	parry_poise_damage = parryPoiseDamage
	
func populate_stats():
	
	attacks_dict = stat_sheet.attacks_dict
	max_health = stat_sheet.max_health
	poise = stat_sheet.max_poise
	poise_recovery = stat_sheet.poise_recovery
	knockback_resistance = stat_sheet.knockback_resistance
	max_poise = poise
		
func update_poise_bar(poise_change):
	
	if(poisebar != null):
		
		poise += poise_change
		
		if(poise <= 0.0):
			stun_modifier = poise / 180.0 #Increases the length of the animation based on how overkill the poise damage was
			print("Stun modifier is " + str(stun_modifier))
			knockback_modifier = absf(poise)#How far the enemy is knocked back when poise overkill occurs (currently no effect)
			
		else:
			stun_modifier = 0.0
			knockback_modifier = 0.0 
		
		poise = clamp(poise, 0.0, max_poise)
		poisebar.value = (poise / max_poise) * 100
		
		if(poise <= 0):
			poisebar.hide()
			if(state != STAGGERED):
				state = STAGGERED
			else:
				state = TAKEHIT
		else:
			poisebar.show()
		

func reserve_attack_position():
	
	var geometry = Geometry2D
	
	for i in playerAttackPoints.size():
		if(!playerAttackPoints[i][0] #Raycast has not collided
		&& !parent.reservedAttackPoints[i] #Point has not been previously reserved
		&& !geometry.is_point_in_polygon(playerAttackPoints[i][1], parent.exclusionArea)
		&& !reserved_index in all_other_reserved_indexes):#Point is not in a forbidden location
				
			reserved_point = playerAttackPoints[i][1]#The actual coordinates to the point are set
			reserved_index = i #Index of point is noted
			index_reserved.emit(reserved_index)
			playerPreviousPosition = reserved_point #playerPreviousPosition is passed into pursue state
			parent.reservedAttackPoints[i] = true #Reserve the point
			
			break

func free_attack_position():
	if(reserved_point != Vector2.ZERO):#Reserved point is not zero
		
		for j in parent.reservedAttackPoints.size():
			if(!parent.compare_float_vectors(reserved_point, playerAttackPoints[reserved_index][1])):#Custom function that uses epsilon to determine approximate equivalence of float vectors
				
				parent.reservedAttackPoints[j] = false
				reserved_point = Vector2.ZERO
				

func get_other_reserved_indexes(index):
	all_other_reserved_indexes.append(index)
