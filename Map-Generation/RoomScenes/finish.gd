extends Node3D

var triggered:bool = false
var player : Player
@export var monks : Array[Node3D] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for monk in monks:
		monk.timeInitial = 1000000000
var messages = ["The Rapture begins.","Alas, I have been Foresaken.","I must ascend through the darkness to reach The Light.","Climb to the fifth floor to Rapture yourself and rejoin your Order.", "Use the left button to move forward and hold the right button to defend yourself."]
var current_message = 0
var message_duration : float = 6
var time : float = 0
@onready var bells: AudioStreamPlayer = $AudioStreamPlayer
@onready var env : WorldEnvironment = $/root/Main/ColorRect/SubViewport/WorldEnvironment
@onready var song: AudioStreamPlayer = $AudioStreamPlayer2
const RESTART = preload("uid://bbsqxsle31m3d")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player && !triggered:
		player = body
		Rapture()
		triggered = true

func Rapture():
	env.environment.fog_enabled = false
	bells.playing = true
	player.console.SendMessage("You finally joined Us, brother.", 4.0)
	await get_tree().create_timer(5.3).timeout
	player.console.SendMessage("We did not know if you were ready.", 4.0)
	await get_tree().create_timer(5.3).timeout
	player.console.SendMessage("Now The Rapture can begin.", 4.0)
	await get_tree().create_timer(5.3).timeout
	bells.playing = false
	song.playing = true
	for monk in monks:
		monk.rapturing = true
		
	player.rapture()
	
	await get_tree().create_timer(20).timeout
	get_tree().root.add_child(RESTART.instantiate())
	
	
	
