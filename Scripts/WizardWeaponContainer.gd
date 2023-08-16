extends Sprite2D

#Handles the visual switching of weapons, for weapon stats see player_stat_sheet

var weaponChildren = []

#var noiseObject = material.get_shader_parameter("noise")

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in get_children():
		weaponChildren.append(i)
	
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#material.set_shader_parameter("texture_size", texture.get_size())
	pass

func switch_weapon_sprite(weapon):
	
	for i in weaponChildren:
		if i.name == weapon:
			i.show()
		else:
			i.hide()
