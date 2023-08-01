extends Sprite2D

#Handles the visual switching of weapons, for weapon stats see player_stat_sheet

var weaponChildren = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in get_children():
		weaponChildren.append(i)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func switch_weapon_sprite(weapon):
	
	for i in weaponChildren:
		if i.name == weapon:
			i.show()
		else:
			i.hide()
