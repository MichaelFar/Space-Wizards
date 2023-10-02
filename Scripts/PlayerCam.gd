extends Camera2D

@export var shouldShake = false

@export var shakeStrength = 10.0

@export var cameraThreshold = 100

@export var maxCameraVelocity = 1200

@onready var MouseCursor = $MouseCursor
var SpellBook = null#Manipulated in spell container 
var mouseRatio = 0.0
var input_vector = Vector2.ZERO #Keep track of player input vector
var parent = null
# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()
	MouseCursor = $MouseCursor
	GlobalCameraValues.cameraNode = self
	SpellBook = get_node("spell_book")

func _process(delta):
	GlobalCameraValues.BOFoffset = offset
	var viewPortRect = get_viewport_rect()
	var cameraVelocity = maxCameraVelocity
	var dimensionsRatio = viewPortRect.size.x / viewPortRect.size.y
	var maxMousePosition = position.distance_to(Vector2(viewPortRect.size.x, viewPortRect.size.y))
	var maxMousePositionX = abs(viewPortRect.size.x * (dimensionsRatio) - parent.position.x)
	var maxMousePositionY = abs(viewPortRect.size.y * (dimensionsRatio) - parent.position.y)
	input_vector = parent.input_vector
	
	mouseRatio = clamp(Vector2.ZERO.distance_to(MouseCursor.position) / maxMousePosition, 0.0, 1.0)
	var mouseRatioX = clamp(Vector2.ZERO.distance_to(MouseCursor.position) / maxMousePositionX, 0.0, 1.0)
	var mouseRatioY = clamp(Vector2.ZERO.distance_to(MouseCursor.position) / maxMousePositionY, 0.0, 1.0)
	
	cameraVelocity = maxCameraVelocity * mouseRatio
	
	offset = offset.move_toward(
	Vector2((MouseCursor.position.normalized() * cameraThreshold).x * mouseRatioX , 
	(MouseCursor.position.normalized() * cameraThreshold).y * mouseRatioY), 
	delta * cameraVelocity)
	
	#Applies a dynamic velocity to the offset to achieve the 'look around' effect
	#cameraThreshold is how far before maximum look has been reached, mouseRationX and Y represent the X and Y directions of the offset, 
	#this ratio changes depending on how far the cursor is from the center of the screen
	GlobalCameraValues.offset = offset
	if(Input.is_action_just_released("CameraToggle")):
		enabled = !enabled
	
	if(shouldShake):
		shake()
	#offset = clamp(offset, Vector2(-cameraThreshold, -cameraThreshold) + global_position, Vector2(cameraThreshold, cameraThreshold) + global_position)
	GlobalCameraValues.EOFoffset = offset
func shake():

	var rObj = RandomNumberGenerator.new()
	
	offset += Vector2(rObj.randf_range(-1.0 * shakeStrength, shakeStrength), rObj.randf_range(-1.0 * shakeStrength, shakeStrength))
	
