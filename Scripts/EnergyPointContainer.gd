extends Node2D

var point_children = []#Contains a list of all point children nodes
var occupied_list = []#Contains list of bools that represent a point's availability, parallel to point_children
var available_list = []#Contains only available points, is not parallel with point children
var energy_particle = null
var particle_children = []#List of energy_particle nodes, not parallel with point children

var player = null

var frame = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	
	post_initialize()
# Called every frame. 'delta' is the elapsed time since the previous frame.

func post_initialize():
	get_point_children()
	energy_particle = preload("res://Scenes/energy_particle.tscn")

func _physics_process(delta):
	frame +=1
	global_position = globals.player.global_position
	
func get_point_children():
	point_children = []
	occupied_list = []
	for i in get_children():
		point_children.append(i)
		occupied_list.append(false)
		
func get_available_positions():
	available_list = []
	for i in occupied_list.size():
		if !occupied_list[i]:
			available_list.append(point_children[i])
			
func gain_energy(energyNum, enemy_position = Vector2.ZERO):

	
	get_available_positions()
	var iterator = 0
	if(particle_children.size() - 1 + energyNum < point_children.size()):
		
		for j in available_list:
			iterator +=1
			if(iterator <= energyNum):
				var particle = energy_particle.instantiate()
				add_child(particle)
				particle_children.append(particle)
				particle.point = j
				if(enemy_position):
					particle.global_position = enemy_position
			
				occupied_list[point_children.find(j)] = true
				print("Found point children " + str(point_children.find(j)))
				
		return true
	
	return false
			
func lose_energy(energyNum): #Use this as a condition to ensure that energy is lost when the condition runs
	#Ensure it is the only condition that is checked unless exclusively using the && operator
	
	var iterator = 0
	
	if(energyNum > particle_children.size()):
		
		return false
		
	else:
		
		for j in particle_children:
			iterator +=1
			print("Freeing position " + str(occupied_list.find(true)))

			if (iterator <= energyNum):
				occupied_list[find_last_taken_spot()] = false
				
				particle_children.pop_at(iterator - 1)
				j.queue_free()#Replace with anim
			else:
				break
		iterator = 0
		for i in occupied_list:
			i = false		
		for i in particle_children:
			occupied_list[iterator] = true
			i.point = point_children[iterator]
			iterator+=1
			
		return true

func find_last_taken_spot():
	var iterator = 0
	for i in occupied_list:
		if !i:
			return iterator - 1
		iterator +=1
			
	return point_children.size() - 1
