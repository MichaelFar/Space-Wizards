extends CharacterBody2D

#Generic enemy ai, randomly wanders within a navigation area minus the 'Exclusion Zone'
#This node will crash if there is no player, navigation area, parent with world.gd script, or exclusion zone
#Provides a good basis for ai going forward
#Uses multiple sprite sheets for animations


var acceleration = 200
var max_speed = 80
var speed = 150
var max_health = 1000.0
var current_health = max_health
var damage_taken = 0.0
var pushBackStrength = 250

var frame = 0
var state = CHOOSEPOINT
var inclusion_area = Vector2.ZERO
var idle_frames = 0
var chosenPoint = Vector2.ZERO
var children = []
var playerPreviousPosition = Vector2.ZERO
const noticeDist = 200
const pursueDist = 80
const attackDist = 40

var attackPosition = Vector2.ZERO

var previousPosition = Vector2.ZERO
var direction = Vector2.ZERO
var stuckFrames = 0

var validPoints = []

var faceRight = true

var animationPlayer = null

@onready var nav = $NavigationAgent2D
@onready var path_desired_distance = nav.get("path_desired_distance")
@onready var target_distance = nav.get("target_desired_distance")
@onready var playerNode = get_node("../Player")
@onready var emoteContainer = $EmoteContainer
@onready var smearContainer = $enemy_attack_container
@onready var healthbar = $Healthbar

enum {
	WANDER,
	ATTACK,
	PURSUE,
	IDLE,
	CHOOSEPOINT,
	TAKEHIT,
	NOTICEPLAYER,
	DEAD
}

func _ready():
	animationPlayer = $AnimationPlayer
	
	for i in self.get_children():
		if i is Sprite2D:
			children.append(i)
	
	healthbar.value = 100
	emoteContainer.play_emote('')

func _physics_process(_delta):#State machine runs per frame
	attackPosition = playerNode.position
	print('Attack position is ' + str(attackPosition))
	match state:
		
		CHOOSEPOINT:#CHOOSEPOINT is used to get a valid point to travel to, then state transitions to WANDER
			if(frame > 2):#Give nav time to update
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
			notice_player_state(_delta)
		IDLE:#The AI will spend some time in this state if it has not noticed the player and has arrived at its destination
			idle_state(_delta)
		TAKEHIT:#Determines what happens when hit
			take_hit_state(_delta)
		DEAD:
			dead_state(_delta)
			
	if(get_parent().playerPosition.distance_to(position) <= noticeDist 
	&& state != NOTICEPLAYER 
	&& state != PURSUE 
	&& state != TAKEHIT
	&& state != ATTACK
	&& state != DEAD):
	#Other states must be interrupted so that the player may be noticed
	#However certain states should not be interrupted, hence the state exclusion in the condition
	#Creates a '?' above the head of an enemy that noticed the player
		change_sprite(get_node('enemy_idle'), chosenPoint)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
		idle_frames = 0
		state = NOTICEPLAYER
		velocity = Vector2.ZERO
		emoteContainer.play_emote('question')
		
	frame += 1 #Frame tracking for various function

func wander_state(target_point, _delta):
	
	nav.target_position = target_point
	
	direction = nav.get_next_path_position() - global_position
	
	if((direction + global_position) == target_point ):
		change_sprite(get_node('enemy_walk'), target_point)
	else:
		change_sprite(get_node('enemy_walk'), direction + global_position)
	
	if(frame % 20 == 0):
		previousPosition = position
	
	if (previousPosition.distance_to(position) < 30):
		stuckFrames += 1
	else:
		stuckFrames = 0
	
	direction = direction.normalized()
	
	velocity = velocity.move_toward(direction * acceleration, _delta * acceleration)
	
	
	if(self.position.distance_to(target_point) <= target_distance || stuckFrames > 300):
		
		state = IDLE
		idle_frames = 0
		change_sprite(get_node('enemy_idle'), target_point)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
		stuckFrames = 0
		emoteContainer.play_emote('')
	
	
	if(self.position.distance_to(target_point) <= attackDist 
	&& state == PURSUE 
	&& playerNode.position.distance_to(target_point) <= 20):
		state = ATTACK
		idle_frames = 0
		stuckFrames = 0
		emoteContainer.play_emote('')
		velocity = Vector2.ZERO
		
		animationPlayer.stop()
		change_sprite(get_node('enemy_attack'), get_parent().playerPosition)
		animationPlayer.play('enemy_attack')
		
	move_and_slide()

func attack_state(_delta):
	
	smearContainer.supplied_player_position = get_parent().get_node('Player').position
	
	print(self.name + " is in attack state")
	if(self.position.distance_to(playerNode.position) >= attackDist):
		if(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
			print("Player out of range, pursuing")
			change_sprite(get_node('enemy_walk'), get_parent().playerPosition)
			animationPlayer.stop()
			animationPlayer.play('enemy_walk')
			state = PURSUE
			idle_frames = 0
			attackPosition = get_parent().get_node('Player').position
			emoteContainer.play_emote('startled')
	else:
		
		if(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
			animationPlayer.stop()
			change_sprite(get_node('enemy_attack'), get_parent().playerPosition)
			animationPlayer.play('enemy_attack')
		elif(animationPlayer.current_animation != 'enemy_attack'):
			animationPlayer.stop()
			change_sprite(get_node('enemy_attack'), get_parent().playerPosition)
			animationPlayer.play('enemy_attack')
		
			
		
func idle_state(_delta):

	velocity = Vector2.ZERO
	idle_frames += 1
	var seconds = 60
	@warning_ignore("integer_division")
	if (idle_frames / seconds == 3):
		state = CHOOSEPOINT
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
	
func choose_point():
	
	var randomPoint = RandomNumberGenerator.new()
	var chosen_point = Vector2.ZERO
	var valueRange = 150
	var travelPoints = []
	
	validPoints = self.get_parent().validpoints
	
	for i in validPoints:
		if i.distance_to(self.position) <= valueRange:
			travelPoints.append(i)
	
	chosen_point = travelPoints[randomPoint.randi_range(0, travelPoints.size() - 1)]
	
	return chosen_point

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
	
	if(area.name == 'AttackHitBox' && state != TAKEHIT):
		
		state = TAKEHIT
		velocity = Vector2.ZERO
		animationPlayer.stop()
		playerPreviousPosition = get_parent().playerNode.position
		change_sprite(get_node("take_hit"), playerPreviousPosition)
		animationPlayer.play("take_hit")
		update_healthbar(area.get_parent().get_parent().currentDamage, area.get_parent().get_parent().currentKnockbackStrength)
		
		
func take_hit_state(_delta):
	var pushBackDirection = position - playerPreviousPosition
	
	pushBackDirection = pushBackDirection.normalized()
	
	if(animationPlayer.current_animation_position == 0):
		
		animationPlayer.play('take_hit')
		
	
	elif(animationPlayer.current_animation_position < animationPlayer.current_animation_length):
		
		velocity = velocity.move_toward(pushBackDirection * pushBackStrength, _delta * pushBackStrength)
		
	elif(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
		
		change_sprite(get_node('enemy_walk'), get_parent().playerPosition)
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
		state = PURSUE
		idle_frames = 0
		playerPreviousPosition = get_parent().playerPosition
		emoteContainer.play_emote('exclaim')
	
	if(current_health <= 0):
		state = DEAD
	move_and_slide()
	
func notice_player_state(_delta):
	
	change_sprite(get_node("enemy_idle"), playerNode.position)
	idle_frames += 1
	
	if(idle_frames / 60 == 3 
	&& position.distance_to(get_parent().playerPosition) <= noticeDist 
	|| position.distance_to(get_parent().playerPosition) < pursueDist):
		
		change_sprite(get_node('enemy_walk'), get_parent().playerPosition)
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
		state = PURSUE
		idle_frames = 0
		playerPreviousPosition = get_parent().playerPosition
		emoteContainer.play_emote('exclaim')
		
	elif(position.distance_to(get_parent().playerPosition) > noticeDist):
		
		idle_frames = 0
		state = CHOOSEPOINT
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
		emoteContainer.play_emote('')
	
func pursue_state(_delta):
	
	if(position.distance_to(get_parent().playerPosition) <= noticeDist):
		playerPreviousPosition = get_parent().playerPosition
	wander_state(playerPreviousPosition, _delta)

func update_healthbar(health_change, knock_back_strength):#pass in negative values to increase health
	
	current_health -= health_change
	healthbar.value = (current_health / max_health) * 100
	print("Health bar value is " + str(healthbar.value))
	pushBackStrength = knock_back_strength

func dead_state(_delta):
	pass
	
