extends GPUParticles2D

var particle_timer_on = false #When the zap spell is done, we do not want to instantly queue_free it
# Called when the node enters the scene tree for the first time.
var frame = 0.0
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(particle_timer_on):
		frame += 1.0
		var frameRate = 1/delta
		if(frame > frameRate / 2.0):
			emitting = false
			frame = 0.0
		if(!emitting):
			if(frame > frameRate / 2.0):
				pass#queue_free()
	
