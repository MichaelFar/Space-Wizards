extends CharacterBody2D

var acceleration = 200
var max_speed = 80
var speed = 150
var frame = 0
var state = CHOOSEPOINT
var inclusion_area = Vector2.ZERO
var idle_frames = 0
var chosenPoint = Vector2.ZERO
var children = []
var playerPreviousPosition = Vector2.ZERO
const noticeDist = 200

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
enum {
	WANDER,
	ATTACK,
	INVESTIGATE,
	IDLE,
	CHOOSEPOINT,
	TAKEHIT,
	NOTICEPLAYER
}

func _ready():
	animationPlayer = $AnimationPlayer
	
	for i in self.get_children():
		if i is Sprite2D:
			children.append(i)
	
		
	emoteContainer.play_emote('')

func _physics_process(_delta):
	
	match state:
		
		CHOOSEPOINT:
			if(frame > 2):#Give nav time to update
				state = WANDER
			chosenPoint = choose_point()
			animationPlayer.stop()
			animationPlayer.play('enemy_walk')
		WANDER:
			wander_state(chosenPoint, _delta)
		ATTACK:
			pass
		INVESTIGATE:
			investigate_state(_delta)
		NOTICEPLAYER:
			notice_player_state(_delta)
		IDLE:
			idle_state(_delta)
		TAKEHIT:
			take_hit_state(_delta)
			
	if(get_parent().playerPosition.distance_to(position) <= noticeDist && state != NOTICEPLAYER && state != INVESTIGATE):
		
		change_sprite(get_node('enemy_idle'), chosenPoint)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
		idle_frames = 0
		state = NOTICEPLAYER
		velocity = Vector2.ZERO
		emoteContainer.play_emote('question')
		
	frame += 1

func wander_state(target_point, _delta):
	
	nav.target_position = target_point
	
	direction = nav.get_next_path_position() - global_position
	
	if(position.distance_to(direction) < position.distance_to(target_point) && direction.x > position.x):
		change_sprite(get_node('enemy_walk'), direction)
	else:
		change_sprite(get_node('enemy_walk'), target_point)
	
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
	
	move_and_slide()

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
		spriteName.flip_h = false
			
	elif(faceRight && position.x > chosen_point.x):
		faceRight = false
		spriteName.flip_h = true
		
	for i in children:
		if(i.name != spriteName.name):
			i.hide()
		else:
			i.show()
			

func _on_hurtbox_area_entered(area):
	
	if(area.name == 'AttackHitBox'):
		
		state = TAKEHIT
		velocity = Vector2.ZERO
		animationPlayer.stop()
		playerPreviousPosition = get_parent().playerNode.position
		change_sprite(get_node("take_hit"), playerPreviousPosition)
		
func take_hit_state(_delta):
	
	var pushBackStrength = 250
	
	var pushBackDirection = position - playerPreviousPosition
	
	pushBackDirection = pushBackDirection.normalized()
	
	if(animationPlayer.current_animation_position == 0):
		
		animationPlayer.play('take_hit')
	
	elif(animationPlayer.current_animation_position < animationPlayer.current_animation_length):
		
		velocity = velocity.move_toward(pushBackDirection * pushBackStrength, _delta * pushBackStrength)
		
	elif(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
		
		change_sprite(get_node('enemy_idle'), chosenPoint)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
		state = IDLE
		idle_frames = 0
	
	move_and_slide()
	
func notice_player_state(_delta):
	change_sprite(get_node("enemy_idle"), playerNode.position)
	idle_frames += 1
	if(idle_frames / 60 == 3 && position.distance_to(get_parent().playerPosition) <= noticeDist):
		
		change_sprite(get_node('enemy_walk'), get_parent().playerPosition)
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
		state = INVESTIGATE
		idle_frames = 0
		playerPreviousPosition = get_parent().playerPosition
		emoteContainer.play_emote('exclaim')
		
	elif(position.distance_to(get_parent().playerPosition) > noticeDist):
		idle_frames = 0
		state = CHOOSEPOINT
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
		
		emoteContainer.play_emote('')
	
	
func investigate_state(_delta):
	
	if(position.distance_to(get_parent().playerPosition) <= noticeDist):
		playerPreviousPosition = get_parent().playerPosition
	wander_state(playerPreviousPosition, _delta)
		
	
