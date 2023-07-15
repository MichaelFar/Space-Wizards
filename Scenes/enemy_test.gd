extends CharacterBody2D


var acceleration = 200
var max_speed = 80
var speed = 150
var frame = 0
var state = CHOOSEPOINT
var spawnArea = Vector2.ZERO
var idle_frames = 0
var chosenPoint = Vector2.ZERO
var children = []


var direction = Vector2.ZERO

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
	spawnArea = get_viewport().get_visible_rect().size
	for i in self.get_children():
		if i is Sprite2D:
			children.append(i)
	validPoints = get_valid_points()

@onready var raycast = $RayCast2D
@onready var exclusion_zone = $"../ExclusionZone"#Get sibling

func _physics_process(_delta):
	
	print("Mouse point is " + str(get_global_mouse_position()))
	print(self.state)
	match state:
		CHOOSEPOINT:
			if(frame > 2):
				state = WANDER
			chosenPoint = choose_point()
			
			change_sprite(get_node('GoblinRun'), chosenPoint)
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
func get_valid_points():
	var validPoints = []
	var geometry = Geometry2D
	var polygon = exclusion_zone.get("polygon")
	if(geometry.is_point_in_polygon(Vector2(370, 160), polygon)):
		print("This is considered valid")
	for i in range(spawnArea.x):
		for j in range(spawnArea.y):
			if(!geometry.is_point_in_polygon(Vector2(i, j), polygon)):
				validPoints.append(Vector2(i,j))
				
	return validPoints

func choose_path(_nav):
	return _nav.get_next_path_position() - global_position

func wander_state(_delta):
	
	nav.target_position = chosenPoint
	if frame % 20 == 0:
		direction = nav.get_next_path_position() - global_position
	print("direction is " + str(direction))
	print("Next point is " + str(chosenPoint) + " and mousepoint is " + str(get_global_mouse_position()))
	direction = direction.normalized()
	
	velocity = velocity.move_toward(direction * acceleration, _delta * acceleration)
	
	if(self.position.distance_to(chosenPoint) <= target_distance):
		state = IDLE
		idle_frames = 0
		change_sprite(get_node('GoblinIdle'), chosenPoint)
		animationPlayer.stop()
		animationPlayer.play('enemy_idle')
	elif(self.position.distance_to(direction) <= path_desired_distance):
		direction = nav.get_next_path_position() - global_position
	move_and_slide()

func idle_state(_delta):
	
	velocity = Vector2.ZERO
	idle_frames += 1
	var seconds = 60
	print("Entering idle state")
	print("Next point is " + str(chosenPoint) + " and current point is " + str(position))
	if (idle_frames / 60 == 3):
		state = CHOOSEPOINT
		change_sprite(get_node('GoblinRun'), chosenPoint)
		animationPlayer.stop()
		animationPlayer.play('enemy_walk')
	
	
func choose_point():
	var randomPoint = RandomNumberGenerator.new()
	var chosen_point = Vector2.ZERO
	
	chosen_point = validPoints[randomPoint.randi_range(0, validPoints.size() - 1)]
	
	
	
	
	#raycast.target_position = self.position
	print("Chosen point is " + str(chosen_point) + " and mousepoint is " + str(get_global_mouse_position()))
	
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
				
