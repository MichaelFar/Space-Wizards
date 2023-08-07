extends Node2D

var raycastChildren = []

var suggestedVector = Vector2.ZERO
@onready var supplied_direction = get_parent().playerPreviousPosition
# Called when the node enters the scene tree for the first time.
var interest_array = []
var danger_array = []
var relevant_raycasts = []
func _ready():
	raycastChildren = set_raycast_children()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#look_at(supplied_direction)
	
	set_relevant_directions()
	set_interest()
	set_danger()
	suggestedVector = get_suggested_vector()
	if(Input.is_action_just_released("relevant_raycasts")):
		print("I am " + str(get_parent().name) + " and supplied_direction is " + str(supplied_direction) + " and relevant raycasts are ")
		for i in raycastChildren:
			print(i.name + ":" 
			+ str(i.target_position) 
			+ " " +str(rad_to_deg(i.target_position.angle_to(supplied_direction))) + ": ,")
		print("The interest array is set to: ")
		for i in interest_array.size():
			print(raycastChildren[i].name + ": " + str(interest_array[i]))
	relevant_raycasts = []
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
	var suggested_vector = Vector2.ZERO
	
	var final_interest = []
	final_interest.resize(interest_array.size())
	for i in interest_array.size():
		
		final_interest[i] = interest_array[i] - danger_array[i]
		
	for i in interest_array.size():
		
		suggested_vector += (raycastChildren[i].target_position) * final_interest[i]
	
	#print("supplied_direction is " + str(supplied_direction) + " and suggested_vector is " + str(suggested_vector.normalized()))
	return suggested_vector.normalized()

func set_danger():# Sets danger based on if the raycasts are colliding or not
	# More complex behavior can be had by making this function have more conditions and having the danger value be more values
	
	var collidingVectorsIndexes = []
	
	for i in raycastChildren.size():
		
		if(raycastChildren[i].is_colliding()):
			collidingVectorsIndexes.append(i)
			danger_array[i] = 1.0
		else:
			danger_array[i] = 0.0
			
	return collidingVectorsIndexes


func set_relevant_directions():
	
	for i in raycastChildren:
		
		if absf(rad_to_deg((i.target_position.normalized()).angle_to(supplied_direction))) <= 90.0:
			relevant_raycasts.append(i)
		#print(str(rad_to_deg(i.target_position.angle_to(supplied_direction))))
				


func set_interest():
	# Set interest in each slot based on world direction
	
		for i in interest_array.size():
			var d = raycastChildren[i].target_position.normalized().dot(supplied_direction)
			interest_array[i] = maxf(0.0, d)
			#print("Set the interest of " + raycastChildren[i].name + " to " + str(interest_array[i]))

