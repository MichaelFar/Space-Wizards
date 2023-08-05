extends Node2D

var raycastChildren = []

var suggested_vector = Vector2.ZERO
@onready var supplied_direction = get_parent().playerPreviousPosition
# Called when the node enters the scene tree for the first time.
var interest_array = []
var danger_array = []

func _ready():
	raycastChildren = set_raycast_children()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#look_at(supplied_direction)
	get_suggested_vector()

func set_raycast_children():
	var raycast_children = []
	for i in get_children():
		if i is RayCast2D:
			raycast_children.append(i)
			interest_array.append(0.0)
			danger_array.append(0.0)
			
	return raycast_children

func set_supplied_direction(newDirection):
	supplied_direction = newDirection

func get_suggested_vector():
	
	var vector_candidate = Vector2.ZERO
	var num_good_rays = 0
	
	for i in raycastChildren:
		if(!i.is_colliding()):
			vector_candidate += i.target_position
			#print("Vector candidate is " + str(vector_candidate))
			num_good_rays += 1
	
	if(num_good_rays == raycastChildren.size() || num_good_rays == 0):
		vector_candidate = Vector2.ZERO
	else:
		vector_candidate = vector_candidate / num_good_rays
	
	suggested_vector = vector_candidate
	#print("Suggested direction is " + str(vector_candidate))

func get_colliding_vectors():
	
	var collidingVectors = []
	
	for i in raycastChildren:
		
		if(i.is_colliding()):
			collidingVectors.append(i)
			
	return collidingVectors
