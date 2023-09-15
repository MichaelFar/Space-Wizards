extends Node2D

var direction = Vector2.ZERO
@export var distance_from_origin = 50
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	direction = get_parent().MouseCursor.position.normalized()
	
	position = direction * distance_from_origin
