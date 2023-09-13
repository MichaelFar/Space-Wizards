extends Camera2D


@export var shouldShake = false

@export var shakeStrength = 10.0

@export var cameraThreshold = 150

@export var maxCameraVelocity = 800

@onready var MouseCursor = $MouseCursor

var mouseRatio = 0.0
var input_vector = Vector2.ZERO #Keep track of player input vector
var parent = null
# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()
	MouseCursor = $MouseCursor
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var cameraVelocity = maxCameraVelocity
	var dimensionsRatio = get_viewport_rect().size.x/get_viewport_rect().size.y
	var maxMousePosition = position.distance_to(Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y))
	var maxMousePositionX = abs(get_viewport_rect().size.x * (dimensionsRatio) - position.x)
	var maxMousePositionY = abs(get_viewport_rect().size.y * (dimensionsRatio) - position.y)
	input_vector = parent.input_vector
	
	#Vector2.ZERO.distance_to(MouseCursor.position), numerator for later
	mouseRatio = clamp(Vector2.ZERO.distance_to(MouseCursor.position) / maxMousePosition, 0.0, 1.0)
	var mouseRatioX = clamp(Vector2.ZERO.distance_to(MouseCursor.position) / maxMousePositionX, 0.0, 1.0)
	var mouseRatioY = clamp(Vector2.ZERO.distance_to(MouseCursor.position) / maxMousePositionY, 0.0, 1.0)
	
	cameraVelocity = maxCameraVelocity * mouseRatio
	
	offset = offset.move_toward(
	Vector2((MouseCursor.position.normalized() * cameraThreshold).x * mouseRatioX , 
	(MouseCursor.position.normalized() * cameraThreshold).y * mouseRatioY), 
	delta * cameraVelocity)
	
	if(Input.is_action_just_released("CameraToggle")):
		enabled = !enabled
	
	if(shouldShake):
		shake()
	#offset = clamp(offset, Vector2(-cameraThreshold, -cameraThreshold) + global_position, Vector2(cameraThreshold, cameraThreshold) + global_position)

func shake():

	var rObj = RandomNumberGenerator.new()
	
	offset += Vector2(rObj.randf_range(-1.0 * shakeStrength, shakeStrength), rObj.randf_range(-1.0 * shakeStrength, shakeStrength))
	
