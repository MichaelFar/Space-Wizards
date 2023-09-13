extends CharacterBody2D

#Container for RAM
#Preloads spells and keeps track of which one is selected
#Will eventually have the control of RAM, which controls how spells are selected
#Needs to speak to player_cam for visual effects and UI

@onready var SpellLoader = $SpellLoader
var parent = null

var PlayerCam = null

var EnergyContainer = null

var MouseCursor = null

var all_possible_spell_resources = [] 

var spell_name_list = []
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
func _physics_process(delta):
	
	#global_position = MouseCursor.global_position
	if(Input.is_action_just_pressed("RAM")):
		#if(EnergyContainer.lose_energy(1)):
		spawn_spell(SpellLoader.get_resource(all_possible_spell_resources[0]), MouseCursor.global_position, get_parent().global_position)

func get_spell_children():
	
	var spellChildren = []
	for i in get_children():
		if '_spell' in i.name:
			spellChildren.append(i)
	return spellChildren
	
func load_spell_children():
	spell_name_list = []
	for i in all_possible_spell_resources:
		spell_name_list.append(i) 

func spawn_spell(selectedSpell : Resource, destination = Vector2.ZERO, origin = Vector2.ZERO): 
	#Some spells do not have a destination, others will need to be provided with one
	#@origin is where the spawned spell will appear from, the spell's parent is actually the scene root
	var spellNode = selectedSpell.instantiate()
	if(destination):
		spellNode.global_destination = destination
	if(origin):
		spellNode.originPoint = origin
		
		get_node('/root').add_child(spellNode)#Sets the child to be of the game root
	global_position = MouseCursor.global_position


