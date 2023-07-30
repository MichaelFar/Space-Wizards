extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	self.texture = load("res://Sprites/player sprite sheets/parry_smear_01.png")
	self.vframes = 3
	self.hframes = 4

	var dynamicParry = Animation.new()
	dynamicParry.add_track(4)
	dynamicParry.length = 0.15

	var path = String(self.get_path()) + ":frame"
	dynamicParry.track_set_path(4, path)
	dynamicParry.track_insert_key(4, 0.0, 0)
	dynamicParry.track_insert_key(4, 0.01, 1)
	
	dynamicParry.value_track_set_update_mode(0, Animation.UPDATE_DISCRETE)
	dynamicParry.loop_mode = 0

	var aPlayer = get_parent().get_node("AttackSpritePlayer")
	
	aPlayer.get_animation_library("").add_animation("dynamic_parry", dynamicParry)
	
