extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func play_emote(emoteName):
	
	var children = get_children()
	
	for i in children:
		
		if i is Sprite2D && i.name == emoteName:
		
			
			i.show()
			$EmotePlayer.play(emoteName)
		
		elif i is Sprite2D:
			i.hide()
