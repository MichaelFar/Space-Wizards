extends Node2D

var point_children = []#Contains a list of all point children nodes
var occupied_list = []#Contains list of bools that represent a point's availability, parallel to point_children
var available_list = []#Contains only available points, is not parallel with point children
var energy_particle = null
var particle_children = []#List of energy_particle nodes, not parallel with point children

# Called when the node enters the scene tree for the first time.
func _ready():
	get_point_children()
	energy_particle = preload("res://Scenes/energy_particle.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	print("My position is " + str(global_position))
	print("Parent position is " + str(get_parent().global_position))

func get_point_children():
	point_children = []
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
	
	if(particle_children.size() - 1 + energyNum < point_children.size()):
		for i in energyNum:
			for j in available_list:
				var particle = energy_particle.instantiate()
				add_child(particle)
				particle_children.append(particle)
				particle.point = j
				if(enemy_position):
					particle.global_position = enemy_position
				occupied_list[point_children.find(j)] = true
				break
		return true
	else:
		return false
			
func lose_energy(energyNum):
	
	var iterator = 0
	
	if(energyNum > particle_children.size()):
		
		return false
		
	else:
		
		for i in energyNum:
			
			for j in particle_children:
				
				occupied_list[occupied_list.find(true)] = false
				particle_children.pop_at(particle_children.find(j))
				j.queue_free()
				
		for i in particle_children:
			
			i.point = point_children[iterator]
			iterator+=1
			
		return true
