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

enum {
	WANDER,
	ATTACK,
	FOLLOW,
	IDLE,
	CHOOSEPOINT,
	TAKEHIT
}

func _ready():
	animationPlayer = $AnimationPlayer
	
	for i in self.get_children():
		if i is Sprite2D:
			children.append(i)
	if(playerNode.position.x > self.position.x):
		faceRight = true
	else:
		faceRight = false




func _physics_process(_delta):
	
	match state:
		CHOOSEPOINT:
			if(frame > 2):#Give nav time to update
				state = WANDER
			chosenPoint = choose_point()
			animationPlayer.stop()
			animationPlayer.play('enemy_walk')
		WANDER:
			wander_state(_delta)
			
		ATTACK:
			pass
		FOLLOW:
			pass
		IDLE:
			idle_state(_delta)
		TAKEHIT:
			take_hit_state(_delta)
	frame += 1

func choose_path(_nav):
	return _nav.get_next_path_position() - global_position

func wander_state(_delta):
	
	nav.target_position = chosenPoint
	
	direction = nav.get_next_path_position() - global_position
	
	if(position.distance_to(direction) < position.distance_to(chosenPoint) && direction.x > position.x):
		change_sprite(get_node('GoblinRun'), direction)
	else:
		change_sprite(get_node('GoblinRun'), chosenPoint)
	
	if(frame % 20 == 0):
		previousPosition = position
	
	if (previousPosition.distance_to(position) < 30):
		stuckFrames += 1
	else:
		stuckFrames = 0
	
	direction = direction.normalized()
	
	velocity = velocity.move_toward(direction * acceleration, _delta * acceleration)
	
	if(self.position.distance_to(chosenPoint) <= target_distance || stuckFrames > 300):
		state = IDLE
		idle_frames = 0
		change_sprite(get_node('GoblinIdle'), chosenPoint)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
		stuckFrames = 0
	elif(self.position.distance_to(direction) <= path_desired_distance):
		direction = nav.get_next_path_position() - global_position
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
#	else:
#		change_sprite(get_node('GoblinIdle'), playerNode.position)
	
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
	
	for i in children:
		if(i.name != spriteName.name):
			i.hide()
		else:
			i.show()
			if(chosen_point.x < position.x && faceRight):
				i.flip_h = true
				faceRight = false
			elif(chosen_point.x > position.x && !faceRight):
				i.flip_h = false
				faceRight = true
				


func _on_hurtbox_area_entered(area):
	
	if(area.name == 'AttackHitBox'):
		
		state = TAKEHIT
		velocity = Vector2.ZERO
		animationPlayer.stop()
		change_sprite(get_node("TakeHit"), self.position)
		playerPreviousPosition = get_parent().playerNode.position

func take_hit_state(_delta):
	
	var pushBackStrength = 250
	
	var pushBackDirection = position - playerPreviousPosition
	
	pushBackDirection = pushBackDirection.normalized()
	if(animationPlayer.current_animation_position == 0):
		animationPlayer.play('take_hit')
		animationPlayer.advance(0)
		
	elif(animationPlayer.current_animation_position < animationPlayer.current_animation_length):
		
		velocity = velocity.move_toward(pushBackDirection * pushBackStrength, _delta * pushBackStrength)
		print("I am being pushed back")
	elif(animationPlayer.current_animation_position == animationPlayer.current_animation_length):
		change_sprite(get_node('GoblinIdle'), chosenPoint)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
		state = IDLE
		idle_frames = 0
	
	move_and_slide()
	
