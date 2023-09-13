extends Node2D

@onready var parent = get_parent()
var MouseMotionEvent = false
var preservedPosition = Vector2.ZERO
var frame = 0
var mouseMotionTimer = 0
var waitForMouse = false
var mouseCooldownFrames = 0
var previousGlobalVector = Vector2.ZERO
var currentGlobalVector = Vector2.ZERO
var vectorDifference = Vector2.ZERO
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	frame +=1
	currentGlobalVector = get_global_mouse_position()
	vectorDifference = currentGlobalVector - previousGlobalVector
	
	if(MouseMotionEvent && mouseCooldownFrames == 0):
		waitForMouse = true
	
	if(waitForMouse):
		mouseCooldownFrames += 1
		if(mouseCooldownFrames / 10 == 1 && !MouseMotionEvent):
			mouseCooldownFrames = 0
			waitForMouse = false
		elif(MouseMotionEvent):
			mouseCooldownFrames = 1
	
	if(!waitForMouse):
		global_position = preservedPosition#global_position.move_toward(preservedPosition, delta * 1000)
	else:
		global_position = get_global_mouse_position()
		preservedPosition = global_position
	
	previousGlobalVector = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	
	MouseMotionEvent = event is InputEventMouseMotion #Will be true if the player is moving the mouse

