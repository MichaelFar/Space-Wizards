extends Camera2D


@export var shouldShake = false

@export var shakeStrength = 10.0

@export var cameraThreshold = 200

@export var maxCameraVelocity = 500

var mouseRatio = 0.0

var parent = null
# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var cameraVelocity = maxCameraVelocity
	var maxMousePosition = Vector2.ZERO.distance_to(Vector2(get_viewport_rect().end.x , get_viewport_rect().end.y))
	
	print(str(maxMousePosition))
	mouseRatio = clamp(Vector2.ZERO.distance_to(get_local_mouse_position()) / maxMousePosition, 0.0, 1.0)
	print("Mouse ratio is " + str(mouseRatio) + " and " + str(Vector2.ZERO.distance_to(get_local_mouse_position()) / maxMousePosition) + " and " + str(get_local_mouse_position()))
	
	cameraVelocity = maxCameraVelocity * mouseRatio
	
	offset = offset.move_toward(
	Vector2((get_local_mouse_position().normalized() * cameraThreshold).x * mouseRatio, 
	(get_local_mouse_position().normalized() * cameraThreshold).y) * mouseRatio, 
	delta * cameraVelocity)
	
	if(Input.is_action_just_released("CameraToggle")):
		enabled = !enabled
	
	if(shouldShake):
		shake()
	#offset = clamp(offset, Vector2(-cameraThreshold, -cameraThreshold) + global_position, Vector2(cameraThreshold, cameraThreshold) + global_position)

func shake():

	var rObj = RandomNumberGenerator.new()
	
	offset += Vector2(rObj.randf_range(-1.0 * shakeStrength, shakeStrength), rObj.randf_range(-1.0 * shakeStrength, shakeStrength))
	
