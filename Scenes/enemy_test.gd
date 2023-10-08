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
var pushBackStrength = 0
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

var cooldown_begin = false

var frame = 0
var state = CHOOSEPOINT
var inclusion_area = Vector2.ZERO
var idle_frames = 0
var chosenPoint = Vector2.ZERO
var children = []
var playerPreviousPosition = Vector2.ZERO
var all_other_reserved_indexes = []
var type = 'enemy_test'
var other_enemies = []

@export var noticeDist = 200
@export var pursueDist = 130
@export var attackDist = 40
var path_desired_distance = 50
var target_distance = 20

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

var originalShader = material
var hit_with_broom = false
@onready var playerNode = get_node("../Player")
@onready var emoteContainer = $EmoteContainer
@onready var smearContainer = $enemy_attack_container
@onready var healthbar = $Healthbar
@onready var poisebar = $poisebar
@onready var navAgent = $NavigationAgent2D
@onready var rayCastContainer = $RayCastContainer
@onready var body_sprite = get_node("PirateAllGreenalien-sheet02")
@onready var parent = get_parent()

@onready var stat_sheet = $pirate_grunt_stat_sheet
@onready var shader = self

var frameRate = 0

var attacks_dict = {}

var player_state = null
var player_damage = 0

signal enemy_attack_stats #Sent to the player in various contexts, such as getting hit
signal player_hit_me #Signal for audio hit noise
signal noticed_player #Signal for alerting nearby enemies (not yet implemented as of 10:08 8/27)

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
		
	parent.spawned_enemy.connect(update_enemy_list)#Signal in parent
	populate_stats()
	shader = shader.get("material")
	playerPreviousPosition = playerNode.position
	target_distance = navAgent.target_desired_distance
	path_desired_distance = navAgent.path_desired_distance
	
func post_initialize():
	#playerNode.get_node("player_stat_sheet").player_stats.connect(get_player_stats)	
	travelPoints = get_ideal_travel_points()
	for i in parent.enemyChildren:
		
		update_enemy_list(i)

func get_ideal_travel_points():
	var travel_points = []
	
	var choice_radius = 150
	validPoints = parent.validpoints
	
	for i in validPoints:
		if i.distance_to((floor(global_position))) <= choice_radius:
			travel_points.append(i)
			
			
	#parent.get_dimensions(travel_points)
	return travel_points

func _physics_process(_delta):#State machine runs per frame
	
	if(playerNode != null):
		attackPosition = playerNode.position
	frameRate = (1/_delta)
	
	
	if frame == 0:
		post_initialize()
	
	if(parent.debug):
		print("State of " + name + " is " + str(state))
	if(int(frame) % (int(frameRate) / 2) == 0 && !(poise <= 0.0)):
		update_poise_bar(poise_recovery)
	
	if(parent.noReservedPoints):
		all_other_reserved_indexes = []
	if(playerNode != null):
		playerAttackPoints = playerNode.attack_points
	
	match state:
		
		CHOOSEPOINT:#CHOOSEPOINT is used to get a valid point to travel to, then state transitions to WANDER
			if(frame > 5):#Give nav time to update
				state = WANDER
				chosenPoint = choose_point()
				animationPlayer.stop()
				animationPlayer.play('enemy_walk')
		WANDER:#Uses A* to navigate to a point, wander_state() is also used for pursuing the player (player position is supplied as an argument)
			wander_state(chosenPoint, _delta)
		ATTACK:
			attack_state(_delta)
		PURSUE:#Supplies a dynamic point (last seen(distance based) player position) to wander_state() function
			pursue_state(_delta)
		NOTICEPLAYER:#Checks how long the player is within noticing distance and determines state change based on this
			notice_player_state(_delta, chosenPoint)
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
	&& state != STAGGERED
	&& playerNode != null):
	#Other states must be interrupted so that the player may be noticed
	#However certain states should not be interrupted, hence the state exclusion in the condition
	#Creates a '?' above the head of an enemy that noticed the player
		state_transition(NOTICEPLAYER,parent.playerPosition)
		
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
	
	
	if(rayCastContainer.debug):
		print("target_point is " + str(target_point) + " and player position is " + str(playerNode.position))
	
	direction = target_point#nav.get_next_path_position() - global_position
	navAgent.target_position = direction
	rayCastContainer.supplied_direction = (navAgent.get_next_path_position()  - floor(global_position)).normalized()#A* next position
	if(parent.compare_float_vectors((direction), target_point)):
		change_sprite(body_sprite, target_point)
	else:
		change_sprite(body_sprite, global_position)
	
	if(frame % 20 == 0):
		previousPosition = position
	
	if (previousPosition.distance_to(position) < 30):
		stuckFrames += 1
	else:
		stuckFrames = 0
	
	velocity = velocity.move_toward(rayCastContainer.suggestedVector * max_speed, acceleration * _delta)
	
	if(state != PURSUE && self.position.distance_to(target_point) <= target_distance || stuckFrames > 300):
		
		state_transition(IDLE, target_point)
	
	#Put better group aggro code here, when we last attempted this and removed it on 9/3/2023 it caused the state transition bug
	
	if(position.distance_to(attackPosition) <= attackDist
	&& state == PURSUE):
		if(parent.debug):
			print("In the wander_state function while in the PURSUE state and I should attack the player")
		state_transition(ATTACK)
		
	elif(state == PURSUE):
		if(parent.debug):
			print("In the wander_state function while in the PURSUE state and I am farther away than attackDist")
	elif(parent.debug):
		print("In the wander_state function and state is " + str(state))
	move_and_slide()

func attack_state(_delta):
	
	if(self.position.distance_to(attackPosition) > attackDist):
		if(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
			print("Player out of range, pursuing")
			state_transition(PURSUE)
			animationPlayer.set("speed_scale", 1.0)
	elif(!coolDownTimerOn):
		print('CoolDownTimer is off and I tried to attack')
		state_transition(ATTACK)
		change_sprite(body_sprite,parent.playerPosition)
		animationPlayer.set("speed_scale", 1.0)
		
	elif(playerNode == null):
		state = IDLE
		
func idle_state(_delta):

	reserved_point = Vector2.ZERO
	velocity = Vector2.ZERO
	idle_frames += 1
	var seconds = frameRate
	@warning_ignore("integer_division")
	if (idle_frames / seconds == 3):
		state_transition(CHOOSEPOINT)
	
func choose_point():
	
	var randomPoint = RandomNumberGenerator.new()
	var chosen_point = Vector2.ZERO
	
	chosen_point = travelPoints[randomPoint.randi_range(0, travelPoints.size() - 1)]
	print("travel_points size in choose_point is " + str(travelPoints.size()))
	print("I am " + name + " and I chose the point " + str(chosen_point))
	
	if((chosen_point) not in validPoints):
		
		travelPoints = get_travel_points()
		chosen_point = travelPoints[randomPoint.randi_range(0, travelPoints.size() - 1)]
		print("I am " + name + " and I changed my point decision" + str(chosen_point))
	
	return chosen_point

func get_travel_points():
	var travel_points = []
	
	var choice_radius = 150
	validPoints = parent.validpoints
	
	for i in validPoints:
		if i.distance_to((floor(global_position))) <= choice_radius:
			travel_points.append(i)
		print("Added " + str(i) + " to travel points")
			
	#parent.get_dimensions(travel_points)
	return travel_points

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
	if(area.get_children()[0].disabled == false && state != DEAD):
		hit_with_broom = true
		if(area.name == 'AttackHitBox' && state != TAKEHIT && state != ATTACK):
			
			velocity = Vector2.ZERO
			animationPlayer.stop()
			playerPreviousPosition = parent.playerNode.position
			change_sprite(body_sprite, playerPreviousPosition)
			animationPlayer.play("take_hit")
			if(state != STAGGERED):
				state = TAKEHIT
			update_healthbar(player_damage)
			update_poise_bar(player_poise_damage)
			player_hit_me.emit()
			
		elif(area.name == 'AttackHitBox' && state == ATTACK):
			
			update_healthbar(player_damage)	
			update_poise_bar(player_poise_damage)
			player_hit_me.emit()
			if(state != STAGGERED):
				animationPlayer.set("speed_scale", 0.5)
			else:
				animationPlayer.stop()
		elif(area.name == 'SpellHitBox' && state != TAKEHIT):
			update_poise_bar(area.get_parent().spell_stat_sheet.get_stats()[2])
			print("Poise value passed from spell is " + str(area.get_parent().spell_stat_sheet.get_stats()[2]))
			update_healthbar(area.get_parent().spell_stat_sheet.get_stats()[1])
			velocity = Vector2.ZERO
			animationPlayer.stop()
			player_poise_damage = area.get_parent().spell_stat_sheet.get_stats()[1]
			playerPreviousPosition = parent.playerNode.position
			change_sprite(body_sprite, playerPreviousPosition)
			animationPlayer.play("take_hit")
			if(state != STAGGERED):
				state = TAKEHIT
			player_hit_me.emit()
			hit_with_broom = false
			#area.get_parent().shouldHit = true
func take_hit_state(_delta, origin = position - playerPreviousPosition):
	
	origin = origin.normalized()
	
	animationPlayer.set("speed_scale", 1.0 + stun_modifier)
	
	if(animationPlayer.current_animation_position == 0):
		reset_player_stats()
		if(state == TAKEHIT):
			animationPlayer.play('take_hit')
			print("State is " + str(state))
			print("In take hit state on frame" + str(frame))
		elif(state == STAGGERED):
			animationPlayer.play('parried')
		
	elif(animationPlayer.current_animation_position < animationPlayer.current_animation_length):
		
		
		velocity = velocity.move_toward(origin * pushBackStrength, pushBackAcceleration)# + knockback_modifier), pushBackAcceleration)
		
	elif(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
		
		state_transition(PURSUE)
		animationPlayer.set("speed_scale", 1.0)
		if(poise <= 0.0):
			update_poise_bar(max_poise)
		
	if(current_health <= 0):
		state = DEAD
	
	move_and_slide()
	
func notice_player_state(_delta, point):#Probably where the collision bug is
	
	if(playerNode != null):
		change_sprite(body_sprite, point)
		idle_frames += 1
		
		if(idle_frames / frameRate == 2 
		&& position.distance_to(attackPosition) <= noticeDist 
		|| position.distance_to(attackPosition) < pursueDist):
			
			state_transition(PURSUE)
			noticed_player.emit(global_position)
		elif(position.distance_to(parent.playerPosition) > noticeDist):
			
			state_transition(CHOOSEPOINT)
		
func pursue_state(_delta):
	
	if(playerNode != null):
		if(position.distance_to(playerNode.position) <= noticeDist):
			playerPreviousPosition = attackPosition
			if(parent.debug):
				print("player was less than notice distance")
		elif(parent.debug):
				print("player was not less than notice distance")
	#	
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
		animationPlayer.play('enemy_death')
		poisebar.queue_free()
		if self == parent.enemyChildren[parent.enemyChildren.find(self)]:
			print("Popped self from enemy list")
		parent.enemyChildren.pop_at(parent.enemyChildren.find(self))
		$CollisionShape2D.disabled = true
	
	if(deadframes / framerate == 2):
		
		
		$"DeathEffect-sheet".show()
		
		
		animationPlayer.play("death")
	elif(deadframes / framerate >= 2):
		shader.set_shader_parameter("dissolve_value", clamp(shader.get_shader_parameter("dissolve_value") - 0.015, 0.0, 1.0))
		if(shader.get_shader_parameter("dissolve_value") == 0.0):
			queue_free()
func flip_h_in_animation():
	
	body_sprite.flip_h = !body_sprite.flip_h

func get_parried(enemy_id):#Function that is called when the player is in parry state and enemy has attacked
	
	print("Self is " + str(self) + " and enemy_id is " + str(enemy_id))
	
	if(enemy_id == self):
		
		update_poise_bar(parry_poise_damage)
		
		velocity = Vector2.ZERO
		animationPlayer.stop()
		playerPreviousPosition = parent.playerNode.position
		change_sprite(body_sprite, playerPreviousPosition)
		animationPlayer.play("parried")
		smearContainer.abort_animation()
		coolDownTimerOn = false
		coolDownFrames = 0
		
func get_player_stats(knock_back_strength, damage, poise_damage, parryPoiseDamage):#Signal emitted from player attack animation
	
	pushBackStrength = knock_back_strength / 2
	pushBackAcceleration = pushBackStrength + knockback_modifier - knockback_resistance
	player_damage = damage
	player_poise_damage = poise_damage
	parry_poise_damage = parryPoiseDamage

func reset_player_stats():#Runs at end of frame to reset stats
	pushBackStrength = 0
	pushBackAcceleration = 0
	player_damage = 0
	player_poise_damage = 0
	parry_poise_damage = 0

func populate_stats():
	
	attacks_dict = stat_sheet.attacks_dict
	max_health = stat_sheet.max_health
	poise = stat_sheet.max_poise
	poise_recovery = stat_sheet.poise_recovery
	knockback_resistance = stat_sheet.knockback_resistance
	pushBackStrength = stat_sheet.knockback_strength
	max_poise = poise
		
func update_poise_bar(poise_change):#update_poise_bar and update_healthbar could be changed in future enemies to have specific behavior occur at certain values
	
	if(poisebar != null):
		
		poise += poise_change
		
		if(poise <= 0.0):
			stun_modifier = clampf(poise / 180.0, 0.0, 1.0) #Increases the length of the animation based on how overkill the poise damage was
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

func node_type():
	type = 'enemy_test'


func state_transition(STATE, point = Vector2.ZERO):
	
	state = STATE
	match STATE:
		ATTACK:
			idle_frames = 0
			stuckFrames = 0
			coolDownFrames = 0
			emoteContainer.play_emote('')
			velocity = Vector2.ZERO
			animationPlayer.stop()
			change_sprite(body_sprite, attackPosition)
			animationPlayer.play('enemy_attack')
			coolDownTimerOn = true
			smearContainer.supplied_player_position = parent.playerPosition
		PURSUE:
			playerPreviousPosition = parent.playerPosition
			change_sprite(body_sprite, parent.playerPosition)
			animationPlayer.stop()
			animationPlayer.play('enemy_walk')
			idle_frames = 0
			emoteContainer.play_emote('exclaim')
		IDLE:
			change_sprite(body_sprite, point)
			animationPlayer.stop()
			animationPlayer.play('enemy_idle')
			stuckFrames = 0
			emoteContainer.play_emote('')
			idle_frames = 0
		CHOOSEPOINT:
			idle_frames = 0
			animationPlayer.stop()
			animationPlayer.play('enemy_walk')
			emoteContainer.play_emote('')
		NOTICEPLAYER:
			change_sprite(body_sprite, point)
			animationPlayer.stop()
			animationPlayer.play('enemy_idle')
			idle_frames = 0
			velocity = Vector2.ZERO
			emoteContainer.play_emote('question')

func update_enemy_list(enemy):

	if enemy != self:
		other_enemies.append(enemy)
		enemy.noticed_player.connect(check_become_aggroed)

func check_become_aggroed(sibling_position):
	if(sibling_position.distance_to(self.global_position) <= noticeDist):
		print("I have become aggroed from sibling")
		state_transition(PURSUE)
func remove_from_tree():
	
	animationPlayer.stop()
	queue_free()

func cost():
	return true
