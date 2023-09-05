extends Camera2D


@export var shouldShake = false

@export var shakeStrength = 10.0

@export var cameraThreshold = 125

@export var cameraVelocity = 300
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if(get_local_mouse_position().distance_to(position) > cameraThreshold):
		offset = offset.move_toward(Vector2((get_local_mouse_position().normalized() * cameraThreshold).x, (get_local_mouse_position().normalized() * cameraThreshold).y) / 2, delta * cameraVelocity)
	
	if(shouldShake):
		shake(delta)
	#offset = clamp(offset, Vector2(-cameraThreshold, -cameraThreshold) + global_position, Vector2(cameraThreshold, cameraThreshold) + global_position)

func shake(delta):

	var rObj = RandomNumberGenerator.new()
	
	offset += Vector2(rObj.randf_range(-1.0 * shakeStrength, shakeStrength), rObj.randf_range(-1.0 * shakeStrength, shakeStrength))
	
