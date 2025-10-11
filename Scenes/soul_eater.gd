extends RigidBody3D
class_name SoulEater

@onready var player : Player = %CharacterBody3D
@onready var animation_player = $AnimationPlayer

var speed : float = 10
var direction : Vector3
var is_withered : bool = false

func _ready():
	contact_monitor = true
	max_contacts_reported = 1

func _physics_process(delta):
	if !is_withered:
		
		direction = player.position - position
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
		
