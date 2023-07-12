extends CharacterBody2D


var attackPlayer = null
var playerSpriteTree = null
var animationState = null
var playerNode = null

func _ready():
	playerNode = get_owner()
	attackPlayer = $"../AttackSpritePlayer"#Get sibling
	playerSpriteTree = $"../PlayerSpriteAnimTree"
	animationState = playerSpriteTree.get("parameters/playback")

func _physics_process(delta):
	
	if(attackPlayer.current_animation_position == 0 && attackPlayer.current_animation_length != 0):
		self.look_at(get_global_mouse_position())
		playerSpriteTree.set("parameters/IdleBlend/blend_position", playerNode.get_local_mouse_position())
		animationState.travel("IdleBlend")
		
	
	
