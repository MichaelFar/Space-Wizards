extends CharacterBody2D

var acceleration = 400
var max_speed = 80
var speed = 150

var state = CHOOSEPOINT
var spawnArea = Vector2.ZERO
var idle_frames = 0
var chosenPoint = Vector2.ZERO

enum {
	WANDER,
	ATTACK,
	FOLLOW,
	IDLE,
	CHOOSEPOINT
}

func _ready():
	spawnArea = get_viewport().get_visible_rect().size


func _physics_process(_delta):
	
	print(self.state)
	match state:
		CHOOSEPOINT:
			chosenPoint = choose_point()
			state = WANDER
		WANDER:
			wander_state(_delta)
			
		ATTACK:
			pass
		FOLLOW:
			pass
		IDLE:
			idle_state(_delta)
	
	
func wander_state(_delta):
	
	
	position = position.move_toward(chosenPoint, speed * _delta)
	
	if(self.position == chosenPoint):
		state = IDLE
		idle_frames = 0
	move_and_slide()

func idle_state(_delta):
	
	idle_frames += 1
	var seconds = 60
	print("Entering idle state")
	if (idle_frames / 60 == 3):
		state = WANDER
	chosenPoint = choose_point()
	
func choose_point():
	var randomPoint = RandomNumberGenerator.new()
	
	return Vector2(randomPoint.randf_range(0,spawnArea.x), randomPoint.randf_range(0,spawnArea.y))
