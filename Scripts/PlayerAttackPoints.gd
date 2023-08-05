extends Node2D

var raycastChildren = []
var valid_attack_points = []


func _ready():
	
	
	raycastChildren = set_raycast_children()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#look_at(supplied_direction)
	valid_attack_points = get_attack_points()
	
func set_raycast_children():
	var raycast_children = []
	for i in get_children():
		if i is RayCast2D:
			raycast_children.append(i)
			
	return raycast_children		
func get_attack_points():
	var AttackPoints = []
	for i in raycastChildren:
		
		AttackPoints.append( [i.is_colliding(), i.target_position + global_position])
			
			#print("Position without collision is " + str(i.target_position))
		
	return AttackPoints		
