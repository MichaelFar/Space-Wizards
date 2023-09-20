extends CharacterBody2D

#Container for RAM
#Preloads spells and keeps track of which one is selected
#Will eventually have the control of RAM, which controls how spells are selected
#Needs to speak to player_cam for visual effects and UI
#Note: Spells must always queue_free() themselves when they are done, this can be accomplished in an animation node


#All spells should handle all behavior within its own scene, this allows for infinite scalability
@onready var SpellLoader = $SpellLoader
@onready var spawn_point = $spawn_point
var camera = null
#@onready var spell_book = $BookUi02
var parent = null

var PlayerCam = null

var EnergyContainer = null

var MouseCursor = null

var all_possible_spell_resources = [] 

var spell_name_list = []

var spell_cooldown_target = 0

var spell_cooldown_frames = 0

var selected_spell_index = 0#Index of spell_name_list that represents the current one selected

var current_spell = null#Holds resource for selected spell scene
var is_open = false
func _ready():
	
	all_possible_spell_resources = SpellLoader.get_resource_list()
	load_spell_children()
	post_initialize()
	
func post_initialize():
	
	parent = get_parent()
	
	PlayerCam = parent.get_node("PlayerCam")
	
	EnergyContainer = parent.get_node("EnergyPointContainer")
	
	MouseCursor = PlayerCam.get_node("MouseCursor")
	
	global_position = MouseCursor.global_position
	
	randomize_list()
	
	current_spell = SpellLoader.get_resource(all_possible_spell_resources[0])
	
	
func _physics_process(delta):
	var frame_rate = 1/delta
	
	
	#This now lives in player.gd, except for cooldown as of 9/20/23
#		if(!spell_cooldown_target):
#
#			spawn_spell(SpellLoader.get_resource(all_possible_spell_resources[0]), 
#					MouseCursor.global_position, 
#					spawn_point.global_position)
						
	if(spell_cooldown_target):
		if(spell_cooldown_frames / spell_cooldown_target == 1):
			spell_cooldown_target = 0
			spell_cooldown_frames = 0
		else:
			spell_cooldown_frames += 1
	
func load_spell_children():
	spell_name_list = []
	for i in all_possible_spell_resources:
		spell_name_list.append(i) 

func spawn_spell(selectedSpell : Resource, destination = Vector2.ZERO, origin = Vector2.ZERO): 
	#Some spells do not have a @destination, others will need to be provided with one
	#@origin is where the spawned spell will appear from, the spell's parent is actually the scene root
	var spellNode = selectedSpell.instantiate()
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
	#global_position = MouseCursor.global_position

func randomize_list():
	#Wrapping this in a function cause I doubt we want to keep the default shuffle() functionality
	spell_name_list.shuffle()

func cycle_spells(direction):
	#Direction is direction that the player will traverse the list, i.e -1 and 1
	selected_spell_index += direction
	if(selected_spell_index + direction < 0): 
		selected_spell_index = all_possible_spell_resources.size() - 1
	elif(selected_spell_index + direction 
		> all_possible_spell_resources.size() - 1):
			selected_spell_index = 0
	
	current_spell = all_possible_spell_resources[selected_spell_index]
	
	
func toggle_book_open():
	if(!is_open):
		PlayerCam.SpellBook.animationPlayer.queue("open_book")
		is_open = true
		
	else:
		PlayerCam.SpellBook.animationPlayer.queue("close_book")
		is_open = false
		
	PlayerCam.SpellBook.material.set_shader_parameter("enabled", is_open)
	return is_open
