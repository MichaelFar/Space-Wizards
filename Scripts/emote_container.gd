extends Node2D

@export var emotePlayer : AnimationPlayer

func play_emote(emoteName):
	
	var children = get_children()
	
	for i in children:
		
		if i is Sprite2D && i.name == emoteName:
		
			i.show()
			emotePlayer.play(emoteName)
		
		elif i is Sprite2D:
			i.hide()
