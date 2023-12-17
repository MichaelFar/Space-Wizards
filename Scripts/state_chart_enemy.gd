extends CharacterBody2D

var player = null
@export var body_sprite : Sprite2D
@export var StateChart : StateChart

var aggro_target = 3.0# time in seconds that the enemy will take to become aggro
func _ready():
	player = globals.player
func _on_area_2d_area_entered(area):
	
	if(area.get_parent() == player):
		StateChart.send_event("player_entered")

func _on_area_2d_area_exited(area):
	if(area.get_parent() == player):
		StateChart.send_event("player_exited")


func _on_observing_state_physics_processing(delta):
	body_sprite.scale.x = 1.0 * sign(player.global_position.x - global_position.x)#Look at player on x-axis
