extends CharacterBody2D

#Container for RAM
#Preloads spells and keeps track of which one is selected
#Will eventually have the control of RAM, which controls how spells are selected
#Needs to speak to player_cam for visual effects and UI
#Note: Spells must always queue_free() themselves when they are done, this can be accomplished in an animation node


#All spells should handle all behavior within its own scene, this allows for infinite scalability

#ALL SPELL NODES NEED THE SAME 4 PROPERTIES TO BE CASTABLE WITHOUT CRASHING
#global_destination
#originPoint
#cost()
#spell_cooldown
@onready var SpellLoader = $SpellLoader
@onready var spawn_point = $spawn_point

#@onready var spell_book = $BookUi02
var shouldChangeIcon = true

var all_possible_spell_resources = [] 

var spell_name_list = []

var spell_cooldown_target = 0

var spell_cooldown_frames = 0

var selected_spell_index = 0#Index of spell_name_list that represents the current one selected

var current_spell = null#Holds resource for selected spell scene

var is_open = false

var book_icon_frame = 0

var frame = 0

var duplicate_resource_list = []

var updated_mouse_coordinate = Vector2.ZERO
var updated_spawn_point = Vector2.ZERO

@onready var parent = get_parent()
		
@onready var camera = parent.get_node("PlayerCam")

@onready var MouseCursor = camera.get_node("MouseCursor")

var shouldCast = false#God help me if this is the solution
#Holds information for proper icon frames and other spell specifics
#If I can help it, this will be the only spell information that lives in spell_container
var spells_dict = {"zap_spell": 
							 {
							 "frame": 8,
							 },
				   "dummy_spell":
							 {
							 "frame": 9,
							 },
				   "dummy_spell 2":
							 {
							 "frame": 57,
							 },
				   "dummy_spell 3":
							 {
							 "frame": 38,
							 },
				   "lesser_heal":
							 {
							 "frame": 53,
							 },
				   "enemy_test":
							 {
							 "frame": 52,
							 },
				   "close_circuit":
							 {
							 "frame": 51,
							 }
					}

func _ready():
	
	all_possible_spell_resources = SpellLoader.get_resource_list()
	load_spell_children()
	post_initialize()
	duplicate_resource_list = convert_to_unpacked_array(all_possible_spell_resources)
func post_initialize():
	
	global_position = MouseCursor.global_position
	
	current_spell = "zap_spell"
	selected_spell_index = spell_name_list.find(current_spell)
	
func convert_to_unpacked_array(packedArray):
	var unpacked_array = []
	for i in packedArray:
		unpacked_array.append(i)
	return unpacked_array
	
func _physics_process(delta):
	var frame_rate = 1/delta
	frame += 1
	updated_mouse_coordinate = MouseCursor.global_position
	updated_spawn_point = spawn_point.global_position
	
	if(shouldChangeIcon):
		
		book_icon_frame = spells_dict[current_spell]["frame"]
		camera.SpellBook.IconInBook.frame = book_icon_frame
		camera.SpellBook.Icons.frame = book_icon_frame
		shouldChangeIcon = false
		
	if(spell_cooldown_target):
		
		if(spell_cooldown_frames / spell_cooldown_target == 1):
			spell_cooldown_target = 0
			spell_cooldown_frames = 0
		else:
			spell_cooldown_frames += 1
	if(camera.SpellBook.should_change_icon):
		trigger_icon_change()
		camera.SpellBook.should_change_icon = false
	
	if(shouldCast):
		cast_spell()
		shouldCast = false
	
func load_spell_children():
	spell_name_list = []
	for i in all_possible_spell_resources:
		spell_name_list.append(i)

func spawn_spell(selectedSpell : Resource, destination = Vector2.ZERO, origin = Vector2.ZERO): 
	#Some spells do not have a @destination, others will need to be provided with one
	#@origin is where the spawned spell will appear from, the spell's parent is actually the scene root
	var spellNode = selectedSpell.instantiate()
	print("Parameters for spawn_spell are:")
	print(str(selectedSpell) + " " + str(destination) + " "+str(origin))
	if(spellNode.cost()):
		if(destination):
			spellNode.global_destination = destination
		if(origin):
			spellNode.originPoint = origin
		
		get_node('/root').add_child(spellNode)#Sets the child to be of the game root
		if(spellNode.cooldown_begin):
			spell_cooldown_target = spellNode.spell_cooldown
			
	else:
		camera.SpellBook.shouldShake = true
		spellNode.queue_free()
	#global_position = MouseCursor.global_position

func randomize_list():
	#Wrapping this in a function cause I doubt we want to keep the default shuffle() functionality
	var rObj = RandomNumberGenerator.new()
	var randomIndex = rObj.randi_range(0, duplicate_resource_list.size() - 1)
	print("Spell name list before shuffle is " + str(duplicate_resource_list))
	duplicate_resource_list.shuffle()
	print("Spell name list after shuffle is " + str(duplicate_resource_list))
	current_spell = duplicate_resource_list[randomIndex]
	selected_spell_index = randomIndex
	shouldChangeIcon = true

func cycle_spells(direction):
	#Direction is direction that the player will traverse the list, i.e -1 and 1
	var previous_spell_index = selected_spell_index
	selected_spell_index = clamp(selected_spell_index + direction, 0, duplicate_resource_list.size() - 1)
	if(previous_spell_index != selected_spell_index):
		if(direction < 0):
			camera.SpellBook.animationPlayer.play("page_left")
		else:
			camera.SpellBook.animationPlayer.play("page_right")
			
	current_spell = duplicate_resource_list[selected_spell_index]
	
	print("Selected spell " + current_spell)

func toggle_book_open():
	
	if(!is_open):
		camera.SpellBook.animationPlayer.queue("open_book")
		is_open = true
		
	else:
		camera.SpellBook.animationPlayer.queue("close_book")
		is_open = false
		
	camera.SpellBook.material.set_shader_parameter("enabled", is_open)
	#camera.SpellBook.IconInBook.material.set_shader_parameter("enabled", is_open)
	return is_open

func trigger_icon_change():
	
	book_icon_frame = spells_dict[current_spell]["frame"]
	camera.SpellBook.IconInBook.frame = book_icon_frame
	camera.SpellBook.Icons.frame = book_icon_frame

func cast_spell():
	if(!spell_cooldown_target):
		print("Arguments before spawning the spell scene are " + str(current_spell) + " " + str(MouseCursor.global_position) + " " + str(spawn_point.global_position))
		spawn_spell(SpellLoader.get_resource(current_spell), 
				MouseCursor.global_position, 
				spawn_point.global_position)

func update_point_values():
	return [updated_mouse_coordinate, updated_spawn_point]
