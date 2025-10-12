extends RigidBody3D
class_name Enemy

@onready var player : Player = %CharacterBody3D
@onready var animation_player = $AnimationPlayer
@onready var area_3d = $Area3D

var speed : float = 10
var direction : Vector3
var is_withered : bool = false
var isInArea: bool = false
var target_pos : Vector3 

func _ready():
	contact_monitor = true
	max_contacts_reported = 1

func _physics_process(delta):
	if isInArea:
		target_pos = player.position - position
		print("is in range")
	if !isInArea:
		print("out of range")
	if !is_withered:
		direction = target_pos
		direction = direction.normalized()
		constant_force = direction*speed
		
func Wither(seconds : float):
	is_withered = true
	constant_force = -constant_force;
	animation_player.play("wither",0.25)
	await get_tree().create_timer(seconds).timeout
	animation_player.play("chasing", 0.25)
	is_withered = false
	
func _on_body_entered(body):
	if body is Player:
		get_tree().change_scene_to_file("res://Scenes/death.tscn")
func _on_area_3d_body_entered(body):
	if body is Player:
		isInArea = true
		
func _on_area_3d_body_exited(body):
	if body is Player:
		isInArea = false
