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

var previousPosition = Vector2.ZERO
var direction = Vector2.ZERO
var stuckFrames = 0

var validPoints = []

var faceRight = true

var animationPlayer = null

@onready var nav = $NavigationAgent2D
@onready var path_desired_distance = nav.get("path_desired_distance")
@onready var target_distance = nav.get("target_desired_distance")

enum {
	WANDER,
	ATTACK,
	FOLLOW,
	IDLE,
	CHOOSEPOINT
}

func _ready():
	animationPlayer = $AnimationPlayer
	
	for i in self.get_children():
		if i is Sprite2D:
			children.append(i)



func _physics_process(_delta):
	
	print("Mouse point is " + str(get_global_mouse_position()))
	print(self.state)
	match state:
		CHOOSEPOINT:
			if(frame > 2):
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
	
	
	if (idle_frames / seconds == 3):
		state = CHOOSEPOINT
		
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
	
	
func choose_point():
	var randomPoint = RandomNumberGenerator.new()
	var chosen_point = Vector2.ZERO
	
	validPoints = self.get_parent().validpoints
	chosen_point = validPoints[randomPoint.randi_range(0, validPoints.size() - 1)]
	
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
				
