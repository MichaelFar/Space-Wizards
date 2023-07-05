extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = Vector2.ZERO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity.y += 1
	velocity.x += 1
