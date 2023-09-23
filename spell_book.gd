extends Sprite2D

@export var shakeStrength = 10.0
@export var shouldShake = false
var parameter_iterator = 0.2
var shakeFrames = 0

@onready var animationPlayer = $AnimationPlayer#So that spell container can reference book animations
@onready var IconContainer = $IconContainer#Box that contains spell icons
@onready var Icons = $Icons #Icon that represents currently selected spell
@onready var IconInBook = $IconInBook #Icon that changes depending on the page



func _ready():
	
	global_position = Vector2(-50.0, get_viewport_rect().size.y * 16.5/20)#Placed in bottom left corner, based on viewport
	animationPlayer.play("initial_state")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var frame_rate = 1 / delta
	
	global_position += GlobalCameraValues.EOFoffset - GlobalCameraValues.BOFoffset 
	
	offset = Vector2.ZERO
	
	if(shouldShake):
		shakeFrames += 1
		shake_book()
	if(shakeFrames / frame_rate >= 0.5):
		shakeFrames = 0
		shouldShake = false
		
	outline_pulse()
	
func shake_book():
	var rObj = RandomNumberGenerator.new() 
	
	offset += Vector2(rObj.randf_range(-1.0 * shakeStrength, shakeStrength), rObj.randf_range(-1.0 * shakeStrength, shakeStrength))

func outline_pulse():
	
	var next_value = material.get_shader_parameter('width') + parameter_iterator
	if(next_value > 5.0 || next_value < 0.0):
		parameter_iterator *= -1
	material.set_shader_parameter('width', next_value)
	
